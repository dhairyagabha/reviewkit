# frozen_string_literal: true

module Changeset
  class Current < ActiveSupport::CurrentAttributes
    attribute :actor, :controller, :source
  end
end
