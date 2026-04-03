# frozen_string_literal: true

require "rails/generators"

module Changeset
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      class_option :mount,
                   type: :boolean,
                   default: true,
                   desc: "Mount Changeset::Engine into the host app routes."
      class_option :mount_path,
                   type: :string,
                   default: "/changeset",
                   desc: "Mount path to use when inserting the engine route."

      def copy_initializer
        template "changeset.rb", "config/initializers/changeset.rb"
      end

      def ensure_importmap
        return if File.exist?(File.join(destination_root, "config", "importmap.rb"))

        template "importmap.rb", "config/importmap.rb"
      end

      def mount_engine
        return unless options[:mount]

        route %(mount Changeset::Engine => "#{options[:mount_path]}")
      end

      def install_migrations
        rake "changeset:install:migrations"
      end

      def print_instructions
        say ""
        say "Changeset installed.", :green
        say "Next steps:"
        say "  1. Run bundle exec rails db:migrate"
        say "  2. Visit #{options[:mount_path]} once you create review data"
        say "  3. Keep javascript_importmap_tags in your layout or use changeset_assets for a custom Changeset layout"
        say "  4. Optionally run rails g changeset:views to copy the shipped UI into the host app"
        say "  5. Optionally run rails g changeset:models for host-side validations, scopes, and callbacks"
        say "  6. Optionally run rails g changeset:controllers to extend permitted params and controller flow"
      end
    end
  end
end
