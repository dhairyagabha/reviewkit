# frozen_string_literal: true

require "rails/generators"

module Reviewkit
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :mount,
                   type: :boolean,
                   default: true,
                   desc: "Mount Reviewkit::Engine into the host app routes."
      class_option :mount_path,
                   type: :string,
                   default: "/reviewkit",
                   desc: "Mount path to use when inserting the engine route."

      def copy_initializer
        template "reviewkit.rb", "config/initializers/reviewkit.rb"
      end

      def ensure_importmap
        return if File.exist?(File.join(destination_root, "config", "importmap.rb"))

        template "importmap.rb", "config/importmap.rb"
      end

      def mount_engine
        return unless options[:mount]

        route %(mount Reviewkit::Engine => "#{options[:mount_path]}")
      end

      def install_migrations
        rake "reviewkit:install:migrations"
      end

      def print_instructions
        say ""
        say "Reviewkit installed.", :green
        say "Next steps:"
        say "  1. Run bundle exec rails db:migrate"
        say "  2. Visit #{options[:mount_path]} once you create review data"
        say "  3. Keep javascript_importmap_tags in your layout or use reviewkit_assets for a custom Reviewkit layout"
        say "  4. Optionally run rails g reviewkit:views to copy the shipped UI into the host app"
        say "  5. Optionally run rails g reviewkit:models for host-side validations, scopes, and callbacks"
        say "  6. Optionally run rails g reviewkit:controllers to extend permitted params and controller flow"
      end
    end
  end
end
