# frozen_string_literal: true

module Reviewkit
  module CommentExtension
    extend ActiveSupport::Concern

    included do
      # Example:
      #
      # before_validation :normalize_comment_source
      # after_update :track_comment_edits, if: :saved_change_to_body?
    end

    private

    def normalize_comment_source
      # Example:
      # metadata["source"] ||= "host_app"
    end
  end
end
