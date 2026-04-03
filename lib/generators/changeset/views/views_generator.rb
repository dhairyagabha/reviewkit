# frozen_string_literal: true

require "rails/generators"

module Changeset
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../", __dir__)

      def copy_views
        directory "app/views/changeset", "app/views/changeset"
      end
    end
  end
end
