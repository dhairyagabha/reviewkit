# frozen_string_literal: true

class AddReviewTypeToReviewkitReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :reviewkit_reviews, :review_type, :string
  end
end
