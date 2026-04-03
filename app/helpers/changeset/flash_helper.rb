# frozen_string_literal: true

module Changeset
  module FlashHelper
    def changeset_flash_class(type)
      base_class = "changeset-flash"

      case type.to_s
      when "notice"
        "#{base_class} #{base_class}--notice"
      when "alert"
        "#{base_class} #{base_class}--alert"
      else
        base_class
      end
    end

    def changeset_flash_shell_class
      base_class = "changeset-flash-shell"

      if changeset_frame_request?
        "#{base_class} #{base_class}--inline"
      else
        "#{base_class} #{base_class}--page"
      end
    end

    def changeset_flash_label(type)
      type.to_s.humanize
    end

    def changeset_flash_role(type)
      type.to_s == "alert" ? "alert" : "status"
    end
  end
end
