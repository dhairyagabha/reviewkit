# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reviewkit::ReviewThread, type: :model do
  it "inherits the review from the document" do
    document = create(:reviewkit_document)
    thread = build(:reviewkit_review_thread, review: nil, document: document)

    expect(thread).to be_valid
    expect(thread.review).to eq(document.review)
  end

  it "requires an anchor line that matches the chosen side" do
    thread = build(:reviewkit_review_thread, side: "old", new_line: 2)
    thread.old_line = nil

    expect(thread).not_to be_valid
    expect(thread.errors[:base]).to include("must include a old line anchor")
  end

  it "rejects documents from a different review" do
    thread = build(
      :reviewkit_review_thread,
      review: create(:reviewkit_review),
      document: create(:reviewkit_document)
    )

    expect(thread).not_to be_valid
    expect(thread.errors[:document]).to include("must belong to the same review")
  end

  it "stores and clears the resolver via a polymorphic association" do
    reviewer = create(:reviewer)
    thread = create(:reviewkit_review_thread)

    Reviewkit::Current.set(actor: reviewer, source: "spec") do
      thread.resolve!
    end

    expect(thread.reload.resolved_by).to eq(reviewer)

    thread.reopen!
    expect(thread.reload.resolved_by).to be_nil
    expect(thread.status).to eq("open")
  end

  it "can be marked outdated" do
    thread = create(:reviewkit_review_thread, status: "open")

    thread.mark_outdated!

    expect(thread.reload.status).to eq("outdated")
  end
end
