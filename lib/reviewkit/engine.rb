# frozen_string_literal: true

module Reviewkit
  class Engine < ::Rails::Engine
    isolate_namespace Reviewkit

    class << self
      def include_host_extension(base_class, extension_name)
        extension = extension_name.safe_constantize
        return unless extension
        return if base_class < extension

        base_class.include(extension)
      end

      def prepend_host_extension(base_class, extension_name)
        extension = extension_name.safe_constantize
        return unless extension
        return if base_class < extension

        base_class.prepend(extension)
      end
    end

    initializer "reviewkit.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    initializer "reviewkit.assets" do |app|
      app.config.assets.paths << root.join("app/assets/builds")
      app.config.assets.precompile += %w[
        reviewkit/application.css
        reviewkit/application.js
      ] if app.config.respond_to?(:assets)
    end

    initializer "reviewkit.turbo_stream" do
      Mime::Type.register "text/vnd.turbo-stream.html", :turbo_stream unless Mime[:turbo_stream]
    end

    initializer "reviewkit.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Reviewkit::ApplicationHelper
      end
    end

    initializer "reviewkit.host_extensions" do
      ActiveSupport::Reloader.to_prepare do
        Engine.include_host_extension(Reviewkit::Review, "Reviewkit::ReviewExtension")
        Engine.include_host_extension(Reviewkit::ReviewThread, "Reviewkit::ReviewThreadExtension")
        Engine.include_host_extension(Reviewkit::Comment, "Reviewkit::CommentExtension")

        Engine.prepend_host_extension(Reviewkit::ReviewsController, "Reviewkit::ReviewsControllerExtension")
        Engine.prepend_host_extension(Reviewkit::ReviewThreadsController, "Reviewkit::ReviewThreadsControllerExtension")
        Engine.prepend_host_extension(Reviewkit::CommentsController, "Reviewkit::CommentsControllerExtension")
      end
    end
  end
end
