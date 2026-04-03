# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Document, type: :model do
  describe "status and diff cache" do
    it "marks a document as added when only new content exists" do
      document = build(:changeset_document, old_content: "", new_content: "const total = 2;\n")

      expect(document).to be_valid
      expect(document.status).to eq("added")
      expect(document.additions_count).to eq(1)
      expect(document.deletions_count).to eq(0)
    end

    it "marks a document as removed when only old content exists" do
      document = build(:changeset_document, old_content: "const total = 1;\n", new_content: "")

      expect(document).to be_valid
      expect(document.status).to eq("removed")
      expect(document.additions_count).to eq(0)
      expect(document.deletions_count).to eq(1)
    end

    it "marks a document as unchanged when contents match" do
      document = build(:changeset_document, old_content: "const total = 1;\n", new_content: "const total = 1;\n")

      expect(document).to be_valid
      expect(document.status).to eq("unchanged")
      expect(document.diff_rows.pluck("kind")).to all(eq("context"))
    end

    it "stringifies review metadata keys" do
      document = create(
        :changeset_document,
        metadata: { resource_id: "app/services/checkouts/submit_order.rb", revision_id: "REV123", resource_type: "ruby_file" }
      )

      expect(document.metadata).to include(
        "resource_id" => "app/services/checkouts/submit_order.rb",
        "revision_id" => "REV123",
        "resource_type" => "ruby_file"
      )
    end
  end

  describe "validations" do
    it "rejects non-hash metadata" do
      document = build(:changeset_document, metadata: "invalid")

      expect(document).not_to be_valid
      expect(document.errors[:metadata]).to include("must be a hash")
    end

    it "enforces unique paths within a review" do
      review = create(:changeset_review)
      create(:changeset_document, review:, path: "rules/cart-tracking.json")
      duplicate = build(:changeset_document, review:, path: "rules/cart-tracking.json")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:path]).to include("has already been taken")
    end
  end
end
