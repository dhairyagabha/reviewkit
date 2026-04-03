# frozen_string_literal: true

require "rails/generators"

module Reviewkit
  module Generators
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path("../../../../", __dir__)

      def copy_views
        directory "app/views/reviewkit", "app/views/reviewkit"
      end
    end
  end
end
