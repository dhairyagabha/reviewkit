# frozen_string_literal: true

module Reviewkit
  class Review < ApplicationRecord
    include NotifiesLifecycleEvents

    enum :status, {
      draft: "draft",
      open: "open",
      approved: "approved",
      rejected: "rejected",
      closed: "closed"
    }, validate: true

    belongs_to :reviewable, polymorphic: true, optional: true
    belongs_to :creator, polymorphic: true, optional: true
    has_many :documents, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :review
    has_many :review_threads, dependent: :destroy, inverse_of: :review

    validates :description, length: { maximum: 10_000 }, allow_blank: true
    validates :title, presence: true
    validate :metadata_must_be_hash

    validate :final_status_requires_all_threads_resolved, if: :will_save_change_to_status?
    before_validation :normalize_metadata

    def open_threads_count
      review_threads.open.count
    end

    def resolved_threads_count
      review_threads.resolved.count
    end

    def approve!
      update!(status: "approved")
    end

    def reject!
      update!(status: "rejected")
    end

    def close!
      update!(status: "closed")
    end

    private

    def normalize_metadata
      self.metadata = metadata.deep_stringify_keys if metadata.is_a?(Hash)
    end

    def final_status_requires_all_threads_resolved
      return unless approved? || closed?
      return unless review_threads.open.exists?

      errors.add(:status, "cannot change while open threads remain")
    end

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
