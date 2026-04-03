# frozen_string_literal: true

require "rails/generators"

module Reviewkit
  module Generators
    class ModelsGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def copy_model_extensions
        template "review_extension.rb", "app/models/concerns/reviewkit/review_extension.rb"
        template "review_thread_extension.rb", "app/models/concerns/reviewkit/review_thread_extension.rb"
        template "comment_extension.rb", "app/models/concerns/reviewkit/comment_extension.rb"
      end

      def print_instructions
        say ""
        say "Reviewkit model extensions installed.", :green
        say "The engine will automatically include these concerns on reload."
        say "Use them to add validations, scopes, and standard Active Record callbacks."
      end
    end
  end
end
