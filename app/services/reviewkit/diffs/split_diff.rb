# frozen_string_literal: true

require "digest/sha1"
require "diff/lcs"

module Reviewkit
  module Diffs
    class SplitDiff
      def self.call(...)
        new(...).call
      end

      def initialize(old_content:, new_content:, review_document_count: nil)
        @old_content = old_content.to_s
        @new_content = new_content.to_s
        @review_document_count = review_document_count
      end

      def call
        old_line_number = 0
        new_line_number = 0
        stats = { "additions" => 0, "deletions" => 0, "changes" => 0, "context" => 0 }
        changes = Diff::LCS.sdiff(lines(@old_content), lines(@new_content)).to_a
        changed_row_count = changes.count { |change| change.action == "!" }

        rows = changes.map do |change|
          case change.action
          when "="
            old_line_number += 1
            new_line_number += 1
            stats["context"] += 1
            build_row("context", old_line_number, new_line_number, change.old_element, change.new_element)
          when "!"
            old_line_number += 1
            new_line_number += 1
            stats["changes"] += 1
            stats["additions"] += 1
            stats["deletions"] += 1
            inline_changes = build_inline_changes(
              change.old_element,
              change.new_element,
              changed_row_count: changed_row_count
            )

            build_row(
              "changed",
              old_line_number,
              new_line_number,
              change.old_element,
              change.new_element,
              inline_changes: inline_changes
            )
          when "-"
            old_line_number += 1
            stats["deletions"] += 1
            build_row("removed", old_line_number, nil, change.old_element, nil)
          when "+"
            new_line_number += 1
            stats["additions"] += 1
            build_row("added", nil, new_line_number, nil, change.new_element)
          end
        end.compact

        { "rows" => rows, "stats" => stats }
      end

      private

      def build_row(kind, old_line, new_line, old_text, new_text, inline_changes: nil)
        normalized_old = old_text.to_s
        normalized_new = new_text.to_s

        row = {
          "kind" => kind,
          "line_code" => Digest::SHA1.hexdigest(
            [ kind, old_line, new_line, normalized_old, normalized_new ].join("\u0000")
          ),
          "new_line" => new_line,
          "new_text" => normalized_new,
          "old_line" => old_line,
          "old_text" => normalized_old
        }

        row["inline_changes"] = inline_changes if inline_changes_present?(inline_changes)
        row
      end

      def lines(content)
        return [] if content.empty?

        content.lines(chomp: true)
      end

      def build_inline_changes(old_text, new_text, changed_row_count:)
        return unless Reviewkit::Diffs::IntralineBudget.allow?(
          old_text: old_text,
          new_text: new_text,
          review_document_count: @review_document_count,
          changed_row_count: changed_row_count
        )

        Reviewkit::Diffs::IntralineDiff.call(old_text:, new_text:)
      end

      def inline_changes_present?(inline_changes)
        return false if inline_changes.blank?

        inline_changes.values.any?(&:present?)
      end
    end
  end
end
