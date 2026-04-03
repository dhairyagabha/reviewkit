# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Diffs::IntralineDiff do
  it "keeps intraline highlights when at least half of the non-whitespace characters are shared" do
    diff = described_class.call(old_text: "status = draft", new_text: "status = open")

    expect(diff).to eq(
      "old" => [ { "start" => 9, "end" => 14 } ],
      "new" => [ { "start" => 9, "end" => 13 } ]
    )
  end

  it "isolates partial edits inside a token when the text is still related" do
    diff = described_class.call(old_text: "ready", new_text: "ready_now")

    expect(diff).to eq(
      "old" => [],
      "new" => [ { "start" => 5, "end" => 9 } ]
    )
  end

  it "highlights punctuation-only insertions" do
    diff = described_class.call(old_text: "order.submit", new_text: "order.submit!")

    expect(diff).to eq(
      "old" => [],
      "new" => [ { "start" => 12, "end" => 13 } ]
    )
  end

  it "highlights whitespace-only changes" do
    diff = described_class.call(old_text: "render  partial", new_text: "render partial")

    expect(diff).to eq(
      "old" => [ { "start" => 7, "end" => 8 } ],
      "new" => []
    )
  end

  it "falls back to whole-line highlighting when similarity stays below fifty percent" do
    diff = described_class.call(old_text: "return draft total", new_text: "archive final email")

    expect(diff).to eq(
      "old" => [],
      "new" => []
    )
  end
end
