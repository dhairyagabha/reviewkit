# frozen_string_literal: true

require "nokogiri"
require "rouge"

module Reviewkit
  module DiffHelper
    def reviewkit_document_badge_class(document)
      case document.status
      when "added"
        "bg-emerald-100 text-emerald-800"
      when "removed"
        "bg-rose-100 text-rose-800"
      when "modified"
        "bg-amber-100 text-amber-900"
      else
        "bg-slate-200 text-slate-700"
      end
    end

    def reviewkit_status_pill_class(review_or_status)
      status = review_or_status.respond_to?(:status) ? review_or_status.status : review_or_status.to_s

      case status
      when "approved"
        "reviewkit-status-pill reviewkit-status-pill--approved"
      when "rejected"
        "reviewkit-status-pill reviewkit-status-pill--rejected"
      when "closed"
        "reviewkit-status-pill reviewkit-status-pill--closed"
      when "resolved"
        "reviewkit-status-pill reviewkit-status-pill--resolved"
      when "outdated"
        "reviewkit-status-pill reviewkit-status-pill--outdated"
      when "draft"
        "reviewkit-status-pill reviewkit-status-pill--draft"
      else
        "reviewkit-status-pill"
      end
    end

    def reviewkit_diff_row_class(row)
      "reviewkit-line reviewkit-line--#{row.fetch("kind")}"
    end

    def reviewkit_unified_group_rows(row, document: nil)
      inline_changes =
        if reviewkit_inline_source_kind(row) == "changed"
          reviewkit_inline_changes(row, document: document)
        else
          row["inline_changes"]
        end

      case row.fetch("kind")
      when "changed"
        [
          reviewkit_unified_row_payload(row, side: "old", kind: "removed", line: row["old_line"], text: row["old_text"], inline_changes: inline_changes),
          reviewkit_unified_row_payload(row, side: "new", kind: "added", line: row["new_line"], text: row["new_text"], inline_changes: inline_changes)
        ]
      when "removed"
        [ reviewkit_unified_row_payload(row, side: "old", kind: "removed", line: row["old_line"], text: row["old_text"], inline_changes: inline_changes) ]
      when "added"
        [ reviewkit_unified_row_payload(row, side: "new", kind: "added", line: row["new_line"], text: row["new_text"], inline_changes: inline_changes) ]
      else
        [ reviewkit_unified_row_payload(row, side: "context", kind: "context", line: row["new_line"] || row["old_line"], text: row["new_text"].presence || row["old_text"], inline_changes: inline_changes) ]
      end
    end

    def reviewkit_inline_ranges(row, side:, document: nil)
      return [] unless reviewkit_inline_source_kind(row) == "changed"

      normalized_side = side.to_s
      return [] unless %w[old new].include?(normalized_side)

      Array(reviewkit_inline_changes(row, document: document)[normalized_side])
    end

    def reviewkit_highlight_line(text, language, inline_ranges: nil, inline_side: nil)
      return "&nbsp;".html_safe if text.blank?

      lexer = Rouge::Lexer.find_fancy(language.to_s, text) || Rouge::Lexers::PlainText.new
      formatter = Rouge::Formatters::HTML.new
      highlighted_html = formatter.format(lexer.lex(text))
      rendered_html = reviewkit_apply_inline_ranges(highlighted_html, inline_ranges, inline_side)

      content_tag(:span, rendered_html, class: "highlight")
    end

    def reviewkit_line_number(value)
      value.presence || "&nbsp;".html_safe
    end

    def reviewkit_render_comment_body(comment)
      simple_format(h(comment.body), class: "reviewkit-comment-body")
    end

    private

    def reviewkit_unified_row_payload(row, side:, kind:, line:, text:, inline_changes:)
      {
        "kind" => kind,
        "line_code" => row.fetch("line_code"),
        "new_line" => side == "old" ? nil : row["new_line"],
        "new_text" => side == "old" ? "" : row["new_text"].to_s,
        "old_line" => side == "new" ? nil : row["old_line"],
        "old_text" => side == "new" ? "" : row["old_text"].to_s,
        "inline_changes" => inline_changes,
        "side" => side,
        "source_kind" => row.fetch("kind"),
        "text" => text.to_s,
        "line" => line
      }
    end

    def reviewkit_inline_source_kind(row)
      row["source_kind"].presence || row["kind"].to_s
    end

    def reviewkit_inline_changes(row, document: nil)
      row["inline_changes"] ||= begin
        context = reviewkit_intraline_context(document)
        old_text = row["old_text"].to_s
        new_text = row["new_text"].to_s

        if Reviewkit::Diffs::IntralineBudget.allow?(
          old_text: old_text,
          new_text: new_text,
          review_document_count: context[:review_document_count],
          changed_row_count: context[:changed_row_count]
        )
          Reviewkit::Diffs::IntralineDiff.call(old_text:, new_text:)
        else
          reviewkit_empty_inline_changes
        end
      end
    end

    def reviewkit_intraline_context(document)
      return {} if document.blank?

      document.instance_variable_get(:@reviewkit_intraline_context) || begin
        context = {
          changed_row_count: document.diff_rows.count { |row| row["kind"] == "changed" },
          review_document_count: document.review&.documents&.size
        }
        document.instance_variable_set(:@reviewkit_intraline_context, context)
      end
    end

    def reviewkit_empty_inline_changes
      { "old" => [], "new" => [] }
    end

    def reviewkit_apply_inline_ranges(highlighted_html, inline_ranges, inline_side)
      normalized_side = inline_side.to_s
      normalized_ranges = reviewkit_merge_inline_ranges(Array(inline_ranges))
      return highlighted_html.html_safe if normalized_ranges.empty? || !%w[old new].include?(normalized_side)

      fragment = Nokogiri::HTML::DocumentFragment.parse(highlighted_html)
      document = fragment.document
      text_offset = 0
      range_index = 0

      fragment.xpath(".//text()").each do |node|
        node_text = node.text
        node_start = text_offset
        node_end = node_start + node_text.length
        text_offset = node_end

        next if node_text.empty?

        range_index += 1 while range_index < normalized_ranges.length && normalized_ranges[range_index].fetch("end") <= node_start

        node_ranges = []
        index = range_index

        while index < normalized_ranges.length && normalized_ranges[index].fetch("start") < node_end
          node_ranges << normalized_ranges[index]
          index += 1
        end

        next if node_ranges.empty?

        cursor = 0
        node_ranges.each do |range|
          local_start = [ range.fetch("start") - node_start, 0 ].max
          local_end = [ range.fetch("end") - node_start, node_text.length ].min
          next if local_start >= local_end

          if local_start > cursor
            node.add_previous_sibling(Nokogiri::XML::Text.new(node_text[cursor...local_start], document))
          end

          wrapper = Nokogiri::XML::Node.new("span", document)
          wrapper["class"] = "reviewkit-inline-change reviewkit-inline-change--#{normalized_side}"
          wrapper.content = node_text[local_start...local_end]
          node.add_previous_sibling(wrapper)
          cursor = local_end
        end

        if cursor < node_text.length
          node.add_previous_sibling(Nokogiri::XML::Text.new(node_text[cursor..], document))
        end

        node.remove
      end

      fragment.to_html.html_safe
    end

    def reviewkit_merge_inline_ranges(ranges)
      ranges
        .map do |range|
          {
            "start" => range["start"] || range[:start],
            "end" => range["end"] || range[:end]
          }
        end
        .select { |range| range["start"].present? && range["end"].present? && range["start"] < range["end"] }
        .sort_by { |range| [ range.fetch("start"), range.fetch("end") ] }
        .each_with_object([]) do |range, merged|
          if merged.empty? || range.fetch("start") > merged.last.fetch("end")
            merged << range
          else
            merged.last["end"] = [ merged.last.fetch("end"), range.fetch("end") ].max
          end
        end
    end
  end
end
