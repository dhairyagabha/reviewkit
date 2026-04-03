# frozen_string_literal: true

class AddReviewTypeToChangesetReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :changeset_reviews, :review_type, :string
  end
end
