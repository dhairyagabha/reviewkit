# frozen_string_literal: true

class CreateReviewkitDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :reviewkit_documents do |t|
      t.references :review, null: false, foreign_key: { to_table: :reviewkit_reviews }
      t.string :path, null: false
      t.string :language, null: false, default: "plaintext"
      t.string :status, null: false, default: "modified"
      t.integer :position, null: false, default: 0
      t.text :old_content
      t.text :new_content
      t.json :diff_cache, null: false, default: {}
      t.json :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :reviewkit_documents, %i[review_id position]
    add_index :reviewkit_documents, %i[review_id path], unique: true
    add_index :reviewkit_documents, :status
  end
end
