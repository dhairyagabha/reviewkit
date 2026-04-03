# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::ApplicationHelper, type: :helper do
  around do |example|
    Changeset.reset_configuration!
    example.run
    Changeset.reset_configuration!
  end

  it "returns the expected document and diff styling helpers" do
    added_document = build(:changeset_document, old_content: "", new_content: "const ready = true;\n")
    removed_document = build(:changeset_document, old_content: "const ready = true;\n", new_content: "")
    modified_document = build(:changeset_document)
    unchanged_document = build(:changeset_document, old_content: "const ready = true;\n", new_content: "const ready = true;\n")
    [ added_document, removed_document, modified_document, unchanged_document ].each(&:valid?)

    expect(helper.changeset_document_badge_class(added_document)).to eq("bg-emerald-100 text-emerald-800")
    expect(helper.changeset_document_badge_class(removed_document)).to eq("bg-rose-100 text-rose-800")
    expect(helper.changeset_document_badge_class(modified_document)).to eq("bg-amber-100 text-amber-900")
    expect(helper.changeset_document_badge_class(unchanged_document)).to eq("bg-slate-200 text-slate-700")
    expect(helper.changeset_diff_row_class({ "kind" => "added" })).to eq("changeset-line changeset-line--added")
    expect(helper.changeset_diff_row_class({ "kind" => "removed" })).to eq("changeset-line changeset-line--removed")
    expect(helper.changeset_diff_row_class({ "kind" => "changed" })).to eq("changeset-line changeset-line--changed")
    expect(helper.changeset_diff_row_class({ "kind" => "context" })).to eq("changeset-line changeset-line--context")
    expect(helper.changeset_line_number(nil)).to include("&nbsp;")
    expect(helper.changeset_line_number(12)).to eq(12)
    expect(helper.changeset_status_pill_class("approved")).to include("approved")
    expect(helper.changeset_status_pill_class("rejected")).to include("rejected")
    expect(helper.changeset_status_pill_class("outdated")).to include("outdated")
  end

  it "builds importmap-friendly asset tags for the engine UI" do
    importmap_tags = helper.changeset_assets(importmap: true)
    module_tags = helper.changeset_assets

    expect(importmap_tags).to include('href="/assets/changeset/application-')
    expect(importmap_tags).to include('type="importmap"')
    expect(importmap_tags).to include('import "changeset/application"')
    expect(module_tags).to include('type="module"')
    expect(module_tags).to include('import "changeset/application"')
  end

  it "wraps content in the requested turbo frame when present" do
    allow(helper.request.headers).to receive(:[]).with("Turbo-Frame").and_return("review_frame")

    wrapped = helper.changeset_wrap_in_frame { "Embedded content" }

    expect(wrapped).to include('turbo-frame id="review_frame"')
    expect(wrapped).to include("Embedded content")
  end

  it "renders highlighted code and comment bodies" do
    comment = build(:changeset_comment, body: "Line one\nLine two")
    highlighted = helper.changeset_highlight_line("const ready = true;", "javascript")
    rendered_comment = helper.changeset_render_comment_body(comment)

    expect(highlighted).to include("highlight")
    expect(rendered_comment).to include("changeset-comment-body")
    expect(rendered_comment).to include("Line one")
    expect(helper.changeset_highlight_line("", "javascript")).to include("&nbsp;")
  end

  it "preserves Rouge syntax markup when wrapping inline changes" do
    highlighted = helper.changeset_highlight_line(
      "def call",
      "ruby",
      inline_ranges: [ { "start" => 0, "end" => 3 } ],
      inline_side: "new"
    )

    expect(highlighted).to include("changeset-inline-change changeset-inline-change--new")
    expect(highlighted).to match(/class="k"><span class="changeset-inline-change changeset-inline-change--new">def<\/span>/)
  end

  it "derives inline ranges for legacy changed rows without cached intraline metadata" do
    legacy_row = {
      "kind" => "changed",
      "old_text" => "ready",
      "new_text" => "ready_now"
    }

    expect(helper.changeset_inline_ranges(legacy_row, side: "old")).to eq([])
    expect(helper.changeset_inline_ranges(legacy_row, side: "new")).to eq([ { "start" => 5, "end" => 9 } ])
    expect(legacy_row["inline_changes"]).to eq(
      "old" => [],
      "new" => [ { "start" => 5, "end" => 9 } ]
    )
  end

  it "falls back to whole-line styling for legacy changed rows that are mostly rewritten" do
    legacy_row = {
      "kind" => "changed",
      "old_text" => "return draft total",
      "new_text" => "archive final email"
    }

    expect(helper.changeset_inline_ranges(legacy_row, side: "old")).to eq([])
    expect(helper.changeset_inline_ranges(legacy_row, side: "new")).to eq([])
    expect(legacy_row["inline_changes"]).to eq(
      "old" => [],
      "new" => []
    )
  end

  it "uses the configured changed-line budget for legacy changed rows when document context is present" do
    Changeset.config.intraline_limits.max_changed_lines = 1
    document = create(
      :changeset_document,
      old_content: "status = draft\nready = false\n",
      new_content: "status = open\nready = true\n"
    )
    legacy_row = document.diff_rows.first.deep_dup
    legacy_row.delete("inline_changes")

    expect(helper.changeset_inline_ranges(legacy_row, side: "old", document: document)).to eq([])
    expect(helper.changeset_inline_ranges(legacy_row, side: "new", document: document)).to eq([])
    expect(legacy_row["inline_changes"]).to eq(
      "old" => [],
      "new" => []
    )
  end

  it "builds actor labels and thread lookups" do
    reviewer = create(:reviewer, name: "Dhairya", email: "dhairya@example.com")
    email_only = create(:reviewer, name: "Anonymous", email: "only@example.com")
    email_only.update_column(:name, "")
    document = create(:changeset_document)
    row = document.diff_rows.first
    thread_index = { [ document.id, row.fetch("line_code") ] => [ "thread-a" ] }

    expect(helper.changeset_actor_label(nil)).to eq("System")
    expect(helper.changeset_actor_label(reviewer)).to eq("Dhairya")
    expect(helper.changeset_actor_label(email_only)).to eq("only@example.com")
    expect(helper.changeset_document_anchor(document)).to eq("document-#{document.id}")
    expect(helper.changeset_document_path_parts("app/services/checkouts/submit_order.rb")).to eq([ "app/services/checkouts/", "submit_order.rb" ])
    expect(helper.changeset_document_path_parts("Gemfile")).to eq([ nil, "Gemfile" ])
    expect(helper.changeset_file_icon).to include("<svg")
    expect(helper.changeset_pencil_icon).to include("<svg")
    expect(helper.changeset_trash_icon).to include("<svg")
    expect(helper.changeset_thread_bucket_id(document, row.fetch("line_code"))).to eq("changeset-document-#{document.id}-line-#{row.fetch("line_code")}")
    expect(helper.changeset_thread_bucket_row_id(document, row.fetch("line_code"))).to eq("changeset-document-#{document.id}-line-#{row.fetch("line_code")}-row")
    expect(helper.changeset_threads_for(thread_index, document, row)).to eq([ "thread-a" ])
    expect(helper.changeset_review_frame_id(document.review)).to match(/review_review_/)
  end

  it "detects whether the current actor can manage comments" do
    reviewer = create(:reviewer)
    other_reviewer = create(:reviewer)
    thread = create(:changeset_review_thread)
    comment = create(:changeset_comment, review_thread: thread, author: reviewer)

    helper.define_singleton_method(:changeset_current_actor) { reviewer }
    expect(helper.changeset_comment_manageable?(comment)).to be(true)
    expect(helper.changeset_comment_destroyable?(comment)).to be(true)
    expect(helper.changeset_thread_manageable?(thread)).to be(true)
    expect(helper.changeset_thread_starter_comment(thread)).to eq(comment)
    expect(helper.changeset_thread_preview(thread)).to include("Looks good")

    helper.define_singleton_method(:changeset_current_actor) { other_reviewer }
    expect(helper.changeset_comment_manageable?(comment)).to be(false)
    expect(helper.changeset_thread_manageable?(thread)).to be(false)
  end

  it "marks comments as edited when they have changed" do
    comment = create(:changeset_comment)

    expect(helper.changeset_comment_edited?(comment)).to be(false)

    comment.update!(body: "Updated body")
    expect(helper.changeset_comment_edited?(comment)).to be(true)
  end

  it "builds unified diff rows from a changed split row" do
    row = {
      "kind" => "changed",
      "line_code" => "line-1",
      "inline_changes" => {
        "old" => [ { "start" => 13, "end" => 14 } ],
        "new" => [ { "start" => 13, "end" => 18 } ]
      },
      "old_line" => 4,
      "new_line" => 4,
      "old_text" => "order.submit!",
      "new_text" => "order.submit!(notify: true)"
    }

    unified_rows = helper.changeset_unified_group_rows(row)

    expect(unified_rows.size).to eq(2)
    expect(unified_rows.first).to include("kind" => "removed", "old_line" => 4, "side" => "old", "source_kind" => "changed")
    expect(unified_rows.last).to include("kind" => "added", "new_line" => 4, "side" => "new", "source_kind" => "changed")
    expect(unified_rows.first["inline_changes"]).to eq(row["inline_changes"])
  end
end
