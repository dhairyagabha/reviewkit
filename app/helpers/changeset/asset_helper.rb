# frozen_string_literal: true

module Changeset
  module AssetHelper
    include Importmap::ImportmapTagsHelper

    def changeset_assets(importmap: false, entry_point: "changeset/application")
      tags = [ changeset_stylesheet_tag ]

      if importmap
        tags << javascript_importmap_tags(entry_point)
      else
        tags << javascript_import_module_tag(entry_point)
      end

      safe_join(tags, "\n")
    end

    def changeset_page_assets(entry_point: "changeset/application")
      if controller.respond_to?(:changeset_engine_layout?, true) && controller.send(:changeset_engine_layout?)
        changeset_assets(importmap: true, entry_point: entry_point)
      else
        changeset_stylesheet_tag
      end
    end

    def changeset_page_module_tag(entry_point: "changeset/application")
      return "".html_safe if controller.respond_to?(:changeset_engine_layout?, true) && controller.send(:changeset_engine_layout?)

      javascript_import_module_tag(entry_point)
    end

    private

    def changeset_stylesheet_tag
      stylesheet_link_tag("changeset/application", media: "all", "data-turbo-track": "reload")
    end
  end
end
