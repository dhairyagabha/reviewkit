# frozen_string_literal: true

class CreateChangesetDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :changeset_documents do |t|
      t.references :review, null: false, foreign_key: { to_table: :changeset_reviews }
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

    add_index :changeset_documents, %i[review_id position]
    add_index :changeset_documents, %i[review_id path], unique: true
    add_index :changeset_documents, :status
  end
end
