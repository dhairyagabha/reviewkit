# frozen_string_literal: true

module Changeset
  class Configuration
    DEFAULT_LAYOUT = "changeset/application"

    class IntralineLimits
      attr_accessor :enabled,
                    :max_review_files,
                    :max_changed_lines,
                    :max_line_length

      def initialize
        @enabled = true
        @max_review_files = 50
        @max_changed_lines = 50
        @max_line_length = 500
      end
    end

    attr_accessor :authorize_action,
                  :current_actor,
                  :intraline_limits,
                  :layout

    def initialize
      @authorize_action = ->(_controller, _action, _record = nil, **_context) { true }
      @current_actor = ->(controller) { controller.respond_to?(:current_user, true) ? controller.send(:current_user) : nil }
      @intraline_limits = IntralineLimits.new
      @layout = DEFAULT_LAYOUT
    end
  end
end
