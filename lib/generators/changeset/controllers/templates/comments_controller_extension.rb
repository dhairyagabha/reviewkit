# frozen_string_literal: true

module Changeset
  module CommentsControllerExtension
    protected

    def permitted_comment_attributes
      super
      # Example:
      # super + %i[comment_type]
    end
  end
end
