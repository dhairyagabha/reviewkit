# frozen_string_literal: true

module Changeset
  module ReviewExtension
    extend ActiveSupport::Concern

    included do
      # Example:
      #
      # validates :review_type, presence: true
      #
      # after_update :notify_host_workflow, if: :saved_change_to_status?
    end

    private

    def notify_host_workflow
      # Example:
      # HostReviewSyncJob.perform_later(id) if approved?
    end
  end
end
