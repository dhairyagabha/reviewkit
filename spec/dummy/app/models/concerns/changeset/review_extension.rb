# frozen_string_literal: true

module Changeset
  module ReviewExtension
    extend ActiveSupport::Concern

    included do
      validates :review_type, inclusion: { in: %w[code content], allow_blank: true }
      after_update :record_host_status_transition, if: :saved_change_to_status?
    end

    class_methods do
      def host_status_transitions
        @host_status_transitions ||= []
      end

      def reset_host_status_transitions!
        host_status_transitions.clear
      end
    end

    private

    def record_host_status_transition
      self.class.host_status_transitions << {
        id: id,
        previous_status: status_before_last_save,
        review_type: review_type,
        status: status
      }
    end
  end
end
