# frozen_string_literal: true

FactoryBot.define do
  factory :changeset_comment, class: "Changeset::Comment" do
    association :review_thread, factory: :changeset_review_thread
    body { "Looks good to me." }
    metadata { {} }
  end
end
