# frozen_string_literal: true

module Changeset
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
