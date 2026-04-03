# frozen_string_literal: true

module Reviewkit
  class ApplicationController < ActionController::Base
    helper ::ApplicationHelper if defined?(::ApplicationHelper)
    helper_method :reviewkit_current_actor,
                  :reviewkit_engine_layout?,
                  :reviewkit_frame_request?,
                  :reviewkit_requested_frame_id

    around_action :set_reviewkit_current_attributes
    layout :reviewkit_layout

    private

    def reviewkit_current_actor
      @reviewkit_current_actor ||= Reviewkit.config.current_actor.call(self)
    end

    def reviewkit_frame_request?
      reviewkit_requested_frame_id.present?
    end

    def reviewkit_requested_frame_id
      request.headers["Turbo-Frame"].presence || params[:reviewkit_frame_id].presence
    end

    def reviewkit_layout
      return false if reviewkit_frame_request?

      @reviewkit_layout ||= begin
        configured_layout = Reviewkit.config.layout
        return configured_layout if configured_layout.present? && configured_layout != Reviewkit::Configuration::DEFAULT_LAYOUT

        if host_layout_override?("reviewkit/application")
          "reviewkit/application"
        elsif host_layout_override?("application")
          "application"
        else
          Reviewkit::Configuration::DEFAULT_LAYOUT
        end
      end
    end

    def reviewkit_engine_layout?
      reviewkit_layout == Reviewkit::Configuration::DEFAULT_LAYOUT
    end

    def authorize_reviewkit!(action, record = nil, **context)
      allowed = Reviewkit.config.authorize_action.call(self, action, record, **context)
      raise Reviewkit::AuthorizationError, "Forbidden action: #{action}" unless allowed
    end

    def host_layout_override?(layout_name)
      basename = layout_name.split("/").last
      relative_directory = layout_name.include?("/") ? File.join("app/views/layouts", File.dirname(layout_name)) : "app/views/layouts"

      Dir.glob(Rails.root.join(relative_directory, "#{basename}.*")).any?
    end

    def set_reviewkit_current_attributes
      Reviewkit::Current.set(
        actor: reviewkit_current_actor,
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
  rescue_from Reviewkit::AuthorizationError, with: :handle_authorization_error
  end
end
