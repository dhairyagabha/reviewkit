# frozen_string_literal: true

module Reviewkit
  module AssetHelper
    include Importmap::ImportmapTagsHelper

    def reviewkit_assets(importmap: false, entry_point: "reviewkit/application")
      tags = [ reviewkit_stylesheet_tag ]

      if importmap
        tags << javascript_importmap_tags(entry_point)
      else
        tags << javascript_import_module_tag(entry_point)
      end

      safe_join(tags, "\n")
    end

    def reviewkit_page_assets(entry_point: "reviewkit/application")
      if controller.respond_to?(:reviewkit_engine_layout?, true) && controller.send(:reviewkit_engine_layout?)
        reviewkit_assets(importmap: true, entry_point: entry_point)
      else
        reviewkit_stylesheet_tag
      end
    end

    def reviewkit_page_module_tag(entry_point: "reviewkit/application")
      return "".html_safe if controller.respond_to?(:reviewkit_engine_layout?, true) && controller.send(:reviewkit_engine_layout?)

      javascript_import_module_tag(entry_point)
    end

    private

    def reviewkit_stylesheet_tag
      stylesheet_link_tag("reviewkit/application", media: "all", "data-turbo-track": "reload")
    end
  end
end
