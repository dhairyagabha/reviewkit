# frozen_string_literal: true

module Reviewkit
  module ReviewsControllerExtension
    protected

    def permitted_review_attributes
      super
      # Example:
      # super + %i[review_type]
    end

    def review_transition_failure_message(review)
      super
      # Example:
      # "#{super} Resolve content approval blockers before marking this review approved."
    end
  end
end
