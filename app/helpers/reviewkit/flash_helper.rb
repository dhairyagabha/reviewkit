# frozen_string_literal: true

module Reviewkit
  module FlashHelper
    def reviewkit_flash_class(type)
      base_class = "reviewkit-flash"

      case type.to_s
      when "notice"
        "#{base_class} #{base_class}--notice"
      when "alert"
        "#{base_class} #{base_class}--alert"
      else
        base_class
      end
    end

    def reviewkit_flash_shell_class
      base_class = "reviewkit-flash-shell"

      if reviewkit_frame_request?
        "#{base_class} #{base_class}--inline"
      else
        "#{base_class} #{base_class}--page"
      end
    end

    def reviewkit_flash_label(type)
      type.to_s.humanize
    end

    def reviewkit_flash_role(type)
      type.to_s == "alert" ? "alert" : "status"
    end
  end
end
