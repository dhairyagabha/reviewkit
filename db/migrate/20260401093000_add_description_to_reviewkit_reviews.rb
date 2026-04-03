# frozen_string_literal: true

class AddDescriptionToReviewkitReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviewkit_reviews, :description, :text
  end
end
