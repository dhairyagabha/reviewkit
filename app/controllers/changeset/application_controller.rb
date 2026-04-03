# frozen_string_literal: true

module Changeset
  class ApplicationController < ActionController::Base
    helper ::ApplicationHelper if defined?(::ApplicationHelper)
    helper_method :changeset_current_actor,
                  :changeset_engine_layout?,
                  :changeset_frame_request?,
                  :changeset_requested_frame_id

    around_action :set_changeset_current_attributes
    layout :changeset_layout

    private

    def changeset_current_actor
      @changeset_current_actor ||= Changeset.config.current_actor.call(self)
    end

    def changeset_frame_request?
      changeset_requested_frame_id.present?
    end

    def changeset_requested_frame_id
      request.headers["Turbo-Frame"].presence || params[:changeset_frame_id].presence
    end

    def changeset_layout
      return false if changeset_frame_request?

      @changeset_layout ||= begin
        configured_layout = Changeset.config.layout
        return configured_layout if configured_layout.present? && configured_layout != Changeset::Configuration::DEFAULT_LAYOUT

        if host_layout_override?("changeset/application")
          "changeset/application"
        elsif host_layout_override?("application")
          "application"
        else
          Changeset::Configuration::DEFAULT_LAYOUT
        end
      end
    end

    def changeset_engine_layout?
      changeset_layout == Changeset::Configuration::DEFAULT_LAYOUT
    end

    def authorize_changeset!(action, record = nil, **context)
      allowed = Changeset.config.authorize_action.call(self, action, record, **context)
      raise Changeset::AuthorizationError, "Forbidden action: #{action}" unless allowed
    end

    def host_layout_override?(layout_name)
      basename = layout_name.split("/").last
      relative_directory = layout_name.include?("/") ? File.join("app/views/layouts", File.dirname(layout_name)) : "app/views/layouts"

      Dir.glob(Rails.root.join(relative_directory, "#{basename}.*")).any?
    end

    def set_changeset_current_attributes
      Changeset::Current.set(
        actor: changeset_current_actor,
        controller: self,
        source: self.class.name
      ) do
        yield
      end
    end

    def handle_authorization_error
      respond_to do |format|
        format.html { redirect_back fallback_location: main_app.respond_to?(:root_path) ? main_app.root_path : "/", alert: "You are not authorized to access that review." }
        format.turbo_stream { head :forbidden }
        format.any { head :forbidden }
      end
    end
  rescue_from Changeset::AuthorizationError, with: :handle_authorization_error
  end
end
