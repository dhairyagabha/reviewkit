# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Diffs::SplitDiff do
  around do |example|
    Changeset.reset_configuration!
    example.run
    Changeset.reset_configuration!
  end

  it "returns an empty diff for blank inputs" do
    diff = described_class.call(old_content: "", new_content: "")

    expect(diff).to eq(
      "rows" => [],
      "stats" => {
        "additions" => 0,
        "deletions" => 0,
        "changes" => 0,
        "context" => 0
      }
    )
  end

  it "captures additions, deletions, and changed rows deterministically" do
    old_content = "const total = 1;\nconsole.log(total);\n"
    new_content = "const total = 2;\nwindow.console.log(total);\nconst ready = true;\n"

    first = described_class.call(old_content:, new_content:)
    second = described_class.call(old_content:, new_content:)

    expect(first["stats"]).to include(
      "additions" => 3,
      "deletions" => 2,
      "changes" => 2,
      "context" => 0
    )
    expect(first["rows"].pluck("kind")).to eq(%w[changed changed added])
    expect(first["rows"].first["inline_changes"]).to eq(
      "old" => [ { "start" => 14, "end" => 15 } ],
      "new" => [ { "start" => 14, "end" => 15 } ]
    )
    expect(first["rows"].second["inline_changes"]).to eq(
      "old" => [],
      "new" => [ { "start" => 0, "end" => 7 } ]
    )
    expect(first["rows"].pluck("line_code")).to eq(second["rows"].pluck("line_code"))
  end

  it "omits cached intraline metadata when the line falls back to whole-line highlighting" do
    diff = described_class.call(
      old_content: "return draft total\n",
      new_content: "archive final email\n"
    )

    expect(diff["rows"]).to contain_exactly(
      include(
        "kind" => "changed",
        "old_text" => "return draft total",
        "new_text" => "archive final email"
      )
    )
    expect(diff["rows"].first).not_to have_key("inline_changes")
  end

  it "skips intraline metadata when the changed-line budget is exceeded" do
    Changeset.config.intraline_limits.max_changed_lines = 1

    diff = described_class.call(
      old_content: "status = draft\nready = false\n",
      new_content: "status = open\nready = true\n"
    )

    expect(diff["rows"].pluck("kind")).to eq(%w[changed changed])
    expect(diff["rows"]).to all(satisfy { |row| !row.key?("inline_changes") })
  end

  it "skips intraline metadata when a changed line exceeds the line-length budget" do
    Changeset.config.intraline_limits.max_line_length = 20

    diff = described_class.call(
      old_content: "summary = 'quarterly revenue'\n",
      new_content: "summary = 'quarterly revenue report'\n"
    )

    expect(diff["rows"]).to contain_exactly(
      include(
        "kind" => "changed",
        "old_text" => "summary = 'quarterly revenue'",
        "new_text" => "summary = 'quarterly revenue report'"
      )
    )
    expect(diff["rows"].first).not_to have_key("inline_changes")
  end
end
