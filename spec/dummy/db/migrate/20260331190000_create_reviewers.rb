# frozen_string_literal: true

class CreateReviewers < ActiveRecord::Migration[8.1]
  def change
    create_table :reviewers do |t|
      t.string :name, null: false
      t.string :email, null: false

      t.timestamps
    end

    add_index :reviewers, :email, unique: true
  end
end
