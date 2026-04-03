# frozen_string_literal: true

module Reviewkit
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end
end
