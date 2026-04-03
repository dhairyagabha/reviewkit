# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Review, type: :model do
  it "stores the creator via a polymorphic association" do
    reviewer = create(:reviewer)
    review = create(:changeset_review, creator: reviewer)

    expect(review.reload.creator).to eq(reviewer)
  end

  it "tracks open and resolved thread counts" do
    review = create(:changeset_review)
    document = create(:changeset_document, review: review)
    resolved_thread = create(:changeset_review_thread, review: review, document: document)
    create(:changeset_review_thread, review: review, document: document)

    Changeset::Current.set(actor: create(:reviewer), source: "spec") do
      resolved_thread.resolve!
    end

    expect(review.open_threads_count).to eq(1)
    expect(review.resolved_threads_count).to eq(1)
  end

  it "rejects non-hash metadata" do
    review = build(:changeset_review, metadata: "invalid")

    expect(review).not_to be_valid
    expect(review.errors[:metadata]).to include("must be a hash")
  end

  it "supports approval and rejection states" do
    review = create(:changeset_review, status: "open")

    review.approve!
    expect(review).to be_approved

    review.reject!
    expect(review).to be_rejected
  end

  it "prevents approval while open threads remain" do
    review = create(:changeset_review, status: "open")
    document = create(:changeset_document, review: review)
    create(:changeset_review_thread, review: review, document: document, status: "open")

    expect { review.approve! }.to raise_error(ActiveRecord::RecordInvalid)

    expect(review.errors[:status]).to include("cannot change while open threads remain")
  end
end
