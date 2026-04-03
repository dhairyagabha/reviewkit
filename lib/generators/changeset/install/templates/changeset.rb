# frozen_string_literal: true

Changeset.configure do |config|
  config.current_actor = lambda do |controller|
    controller.respond_to?(:current_user, true) ? controller.send(:current_user) : nil
  end

  config.authorize_action = lambda do |_controller, _action, _record = nil, **_context|
    true
  end

  config.layout = "changeset/application"

  # Keep intraline highlighting conservative by default so large reviews
  # fall back to line-level diffs before they become expensive.
  config.intraline_limits.max_review_files = 50
  config.intraline_limits.max_changed_lines = 50
  config.intraline_limits.max_line_length = 500
end
