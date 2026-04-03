# frozen_string_literal: true

require "importmap-rails"
require "turbo-rails"
require "reviewkit/version"
require "reviewkit/configuration"
require "reviewkit/engine"

module Reviewkit
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
