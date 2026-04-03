# frozen_string_literal: true

module Reviewkit
  class Comment < ApplicationRecord
    include NotifiesLifecycleEvents

    belongs_to :review_thread, inverse_of: :comments
    belongs_to :author, polymorphic: true, optional: true

    delegate :document, :review, to: :review_thread

    validates :body, presence: true
    validate :metadata_must_be_hash

    before_validation :normalize_metadata

    private

    def normalize_metadata
      self.metadata = metadata.deep_stringify_keys if metadata.is_a?(Hash)
    end

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
