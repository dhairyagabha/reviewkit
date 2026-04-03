# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reviewkit::Reviews::Create do
  let(:reviewer) { create(:reviewer) }

  around do |example|
    Reviewkit.reset_configuration!
    example.run
    Reviewkit.reset_configuration!
  end

  it "creates a review, documents, and preserves the creator context" do
    review = described_class.call(
      title: "Checkout hardening review",
      description: "Review the checkout status transition changes.",
      creator: reviewer,
      external_reference: "PR-42",
      status: "open",
      metadata: {
        pull_request: "PR-42",
        branch: "feature/checkout-guard"
      },
      review_attributes: {
        review_type: "code"
      },
      documents: [
        {
          path: "app/services/checkouts/submit_order.rb",
          language: "ruby",
          old_content: "def call(order)\n  order.submit!\nend\n",
          new_content: "def call(order)\n  return false unless order.ready?\n\n  order.submit!\nend\n",
          metadata: {
            resource_id: "submit_order",
            revision_id: "abc123"
          }
        }
      ]
    )

    expect(review).to be_persisted
    expect(review.creator).to eq(reviewer)
    expect(review.review_type).to eq("code")
    expect(review.status).to eq("open")
    expect(review.metadata).to include("pull_request" => "PR-42", "branch" => "feature/checkout-guard")

    document = review.documents.first
    expect(review.documents.size).to eq(1)
    expect(document.path).to eq("app/services/checkouts/submit_order.rb")
    expect(document.language).to eq("ruby")
    expect(document.metadata).to include("resource_id" => "submit_order", "revision_id" => "abc123")
  end

  it "falls back to line-level diffs when the review file budget is exceeded" do
    Reviewkit.config.intraline_limits.max_review_files = 1

    review = described_class.call(
      title: "Large review",
      creator: reviewer,
      documents: [
        {
          path: "app/models/order.rb",
          language: "ruby",
          old_content: "status = draft\n",
          new_content: "status = open\n"
        },
        {
          path: "app/models/invoice.rb",
          language: "ruby",
          old_content: "badge = 'Paid'\n",
          new_content: "badge = 'Paid in full'\n"
        }
      ]
    )

    changed_rows = review.documents.flat_map(&:diff_rows).select { |row| row["kind"] == "changed" }

    expect(changed_rows).not_to be_empty
    expect(changed_rows).to all(satisfy { |row| !row.key?("inline_changes") })
  end
end
