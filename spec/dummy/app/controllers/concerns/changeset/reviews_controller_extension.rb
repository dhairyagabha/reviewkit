# frozen_string_literal: true

module Changeset
  module ReviewsControllerExtension
    protected

    def permitted_review_attributes
      super + %i[review_type]
    end
  end
end
