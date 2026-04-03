# frozen_string_literal: true

require "importmap-rails"
require "turbo-rails"
require "changeset/version"
require "changeset/configuration"
require "changeset/engine"

module Changeset
  class Error < StandardError; end
  class AuthorizationError < Error; end

  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield(config)
    end

    def reset_configuration!
      @config = Configuration.new
    end
  end
end
