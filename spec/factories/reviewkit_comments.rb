# frozen_string_literal: true

FactoryBot.define do
  factory :reviewkit_comment, class: "Reviewkit::Comment" do
    association :review_thread, factory: :reviewkit_review_thread
    body { "Looks good to me." }
    metadata { {} }
  end
end
