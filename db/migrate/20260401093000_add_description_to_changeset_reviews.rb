# frozen_string_literal: true

class AddDescriptionToChangesetReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :changeset_reviews, :description, :text
  end
end
