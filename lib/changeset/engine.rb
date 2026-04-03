# frozen_string_literal: true

module Changeset
  class Engine < ::Rails::Engine
    isolate_namespace Changeset

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

    initializer "changeset.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
    end

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    initializer "changeset.assets" do |app|
      app.config.assets.paths << root.join("app/assets/builds")
      app.config.assets.precompile += %w[
        changeset/application.css
        changeset/application.js
      ] if app.config.respond_to?(:assets)
    end

    initializer "changeset.turbo_stream" do
      Mime::Type.register "text/vnd.turbo-stream.html", :turbo_stream unless Mime[:turbo_stream]
    end

    initializer "changeset.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Changeset::ApplicationHelper
      end
    end

    initializer "changeset.host_extensions" do
      ActiveSupport::Reloader.to_prepare do
        Engine.include_host_extension(Changeset::Review, "Changeset::ReviewExtension")
        Engine.include_host_extension(Changeset::ReviewThread, "Changeset::ReviewThreadExtension")
        Engine.include_host_extension(Changeset::Comment, "Changeset::CommentExtension")

        Engine.prepend_host_extension(Changeset::ReviewsController, "Changeset::ReviewsControllerExtension")
        Engine.prepend_host_extension(Changeset::ReviewThreadsController, "Changeset::ReviewThreadsControllerExtension")
        Engine.prepend_host_extension(Changeset::CommentsController, "Changeset::CommentsControllerExtension")
      end
    end
  end
end
