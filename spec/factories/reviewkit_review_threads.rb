# frozen_string_literal: true

FactoryBot.define do
  factory :reviewkit_review_thread, class: "Reviewkit::ReviewThread" do
    association :document, factory: :reviewkit_document
    review { document.review }
    status { "open" }
    metadata do
      {
        "resource_id" => "RC123",
        "revision_id" => "REV_CURRENT"
      }
    end

    transient do
      diff_row { document.diff_rows.detect { |row| row["kind"] != "context" } || document.diff_rows.first }
    end

    after(:build) do |thread, evaluator|
      thread.document.valid?
      row = evaluator.diff_row
      thread.line_code ||= row.fetch("line_code")
      thread.side ||= row["new_line"].present? ? "new" : "old"
      thread.old_line ||= row["old_line"]
      thread.new_line ||= row["new_line"]
    end
  end
end
