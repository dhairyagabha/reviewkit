# frozen_string_literal: true

module Reviewkit
  class Current < ActiveSupport::CurrentAttributes
    attribute :actor, :controller, :source
  end
end
