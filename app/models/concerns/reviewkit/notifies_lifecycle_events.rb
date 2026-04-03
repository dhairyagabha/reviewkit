# frozen_string_literal: true

module Reviewkit
  module NotifiesLifecycleEvents
    extend ActiveSupport::Concern

    included do
      after_create_commit -> { instrument_reviewkit_event(:created) }
      after_update_commit :instrument_reviewkit_update_events
      after_destroy_commit -> { instrument_reviewkit_event(:destroyed) }
    end

    private

    def instrument_reviewkit_update_events
      instrument_reviewkit_event(:updated)
      return unless respond_to?(:saved_change_to_status?) && saved_change_to_status?

      from, to = saved_change_to_status
      instrument_reviewkit_event(:status_changed, from:, to:)
    end

    def instrument_reviewkit_event(event, **payload)
      ActiveSupport::Notifications.instrument(
        "reviewkit.#{self.class.model_name.element}.#{event}",
        reviewkit_notification_payload.merge(payload.compact)
      )
    end

    def reviewkit_notification_payload
      {
        actor: Reviewkit::Current.actor,
        controller: Reviewkit::Current.controller,
        record: self,
        source: Reviewkit::Current.source
      }.compact
    end
  end
end
