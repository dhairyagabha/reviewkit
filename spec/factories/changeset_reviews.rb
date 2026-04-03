# frozen_string_literal: true

FactoryBot.define do
  factory :changeset_review, class: "Changeset::Review" do
    sequence(:title) { |n| "Review #{n}" }
    description { "This review tightens the checkout submission flow before merge." }
    status { "open" }
    metadata do
      {
        "pull_request" => "PR-42",
        "branch" => "feature/checkout-guard",
        "base_branch" => "main"
      }
    end
  end
end
