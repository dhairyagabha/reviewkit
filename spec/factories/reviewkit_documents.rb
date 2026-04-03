# frozen_string_literal: true

FactoryBot.define do
  factory :reviewkit_document, class: "Reviewkit::Document" do
    association :review, factory: :reviewkit_review
    sequence(:path) { |n| "rule_components/custom_code_#{n}.js" }
    language { "javascript" }
    old_content { "const total = 1;\nconsole.log(total);\n" }
    new_content { "const total = 2;\nwindow.console.log(total);\n" }
    sequence(:position) { |n| n }
    metadata do
      {
        "resource_id" => "RC123",
        "resource_type" => "rule_component",
        "revision_id" => "REV_CURRENT",
        "base_revision_id" => "REV_BASE"
      }
    end
  end
end
