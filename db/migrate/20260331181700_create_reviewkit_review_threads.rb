# frozen_string_literal: true

class CreateReviewkitReviewThreads < ActiveRecord::Migration[8.1]
  def change
    create_table :reviewkit_review_threads do |t|
      t.references :review, null: false, foreign_key: { to_table: :reviewkit_reviews }
      t.references :document, null: false, foreign_key: { to_table: :reviewkit_documents }
      t.string :status, null: false, default: "open"
      t.string :side, null: false, default: "new"
      t.integer :old_line
      t.integer :new_line
      t.string :line_code, null: false
      t.datetime :resolved_at
      t.references :resolved_by, polymorphic: true, null: true
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :reviewkit_review_threads, %i[document_id line_code]
    add_index :reviewkit_review_threads, :status
  end
end
