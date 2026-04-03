# frozen_string_literal: true

require "rails/generators"

module Reviewkit
  module Generators
    class ControllersGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_controller_extensions
        template "reviews_controller_extension.rb", "app/controllers/concerns/reviewkit/reviews_controller_extension.rb"
        template "review_threads_controller_extension.rb", "app/controllers/concerns/reviewkit/review_threads_controller_extension.rb"
        template "comments_controller_extension.rb", "app/controllers/concerns/reviewkit/comments_controller_extension.rb"
      end

      def print_instructions
        say ""
        say "Reviewkit controller extensions installed.", :green
        say "The engine will automatically prepend these modules on reload."
        say "Use them to extend permitted params, scopes, redirects, and review flow behavior."
      end
    end
  end
end
