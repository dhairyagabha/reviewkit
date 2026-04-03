# frozen_string_literal: true

FactoryBot.define do
  factory :reviewer do
    sequence(:name) { |n| "Reviewer #{n}" }
    sequence(:email) { |n| "reviewer#{n}@example.com" }
  end
end
