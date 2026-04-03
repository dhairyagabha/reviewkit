# frozen_string_literal: true

module Changeset
  module NotifiesLifecycleEvents
    extend ActiveSupport::Concern

    included do
      after_create_commit -> { instrument_changeset_event(:created) }
      after_update_commit :instrument_changeset_update_events
      after_destroy_commit -> { instrument_changeset_event(:destroyed) }
    end

    private

    def instrument_changeset_update_events
      instrument_changeset_event(:updated)
      return unless respond_to?(:saved_change_to_status?) && saved_change_to_status?

      from, to = saved_change_to_status
      instrument_changeset_event(:status_changed, from:, to:)
    end

    def instrument_changeset_event(event, **payload)
      ActiveSupport::Notifications.instrument(
        "changeset.#{self.class.model_name.element}.#{event}",
        changeset_notification_payload.merge(payload.compact)
      )
    end

    def changeset_notification_payload
      {
        actor: Changeset::Current.actor,
        controller: Changeset::Current.controller,
        record: self,
        source: Changeset::Current.source
      }.compact
    end
  end
end
