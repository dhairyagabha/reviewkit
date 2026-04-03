# frozen_string_literal: true

module Reviewkit
  module ReviewThreadsControllerExtension
    protected

    def permitted_review_thread_attributes
      super
      # Example:
      # super + %i[source_revision_id]
    end
  end
end
