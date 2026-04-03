# frozen_string_literal: true

class CreateReviewkitReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviewkit_reviews do |t|
      t.string :title, null: false
      t.string :status, null: false, default: "draft"
      t.references :reviewable, polymorphic: true, null: true
      t.string :external_reference
      t.references :creator, polymorphic: true, null: true
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :reviewkit_reviews, :status
    add_index :reviewkit_reviews, :external_reference
  end
end
