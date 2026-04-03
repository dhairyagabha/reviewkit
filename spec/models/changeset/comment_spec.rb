# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Comment, type: :model do
  it "stores the author via a polymorphic association" do
    reviewer = create(:reviewer)
    comment = create(:changeset_comment, author: reviewer)

    expect(comment.reload.author).to eq(reviewer)
  end

  it "rejects non-hash metadata" do
    comment = build(:changeset_comment, metadata: "invalid")

    expect(comment).not_to be_valid
    expect(comment.errors[:metadata]).to include("must be a hash")
  end

  it "delegates review and document through its review thread" do
    comment = create(:changeset_comment)

    expect(comment.review).to eq(comment.review_thread.review)
    expect(comment.document).to eq(comment.review_thread.document)
  end
end
