# frozen_string_literal: true

module Reviewkit
  module ReviewThreadExtension
    extend ActiveSupport::Concern

    included do
      # Example:
      #
      # validate :ensure_thread_context_is_present
      # after_update :notify_thread_status_change, if: :saved_change_to_status?
    end

    private

    def ensure_thread_context_is_present
      # Example:
      # errors.add(:metadata, "must include a resource_id") if metadata["resource_id"].blank?
    end
  end
end
