# frozen_string_literal: true

class Reviewer < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :name, presence: true
end
