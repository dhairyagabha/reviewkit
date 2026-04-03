# frozen_string_literal: true

class CreateChangesetComments < ActiveRecord::Migration[8.1]
  def change
    create_table :changeset_comments do |t|
      t.references :review_thread, null: false, foreign_key: { to_table: :changeset_review_threads }
      t.references :author, polymorphic: true, null: true
      t.text :body, null: false
      t.datetime :edited_at
      t.json :metadata, null: false, default: {}

      t.timestamps
    end
  end
end
