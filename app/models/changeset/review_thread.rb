# frozen_string_literal: true

module Changeset
  class ReviewThread < ApplicationRecord
    include NotifiesLifecycleEvents

    enum :status, {
      open: "open",
      resolved: "resolved",
      outdated: "outdated"
    }, validate: true

    belongs_to :review, inverse_of: :review_threads
    belongs_to :document, inverse_of: :review_threads
    belongs_to :resolved_by, polymorphic: true, optional: true
    has_many :comments, -> { order(:created_at, :id) }, dependent: :destroy, inverse_of: :review_thread

    validates :line_code, presence: true
    validates :side, presence: true
    validates :side, inclusion: { in: %w[old new] }
    validate :anchor_line_must_match_side
    validate :document_must_belong_to_review
    validate :metadata_must_be_hash

    before_validation :assign_review_from_document
    before_validation :normalize_metadata

    scope :open, -> { where(status: "open") }
    scope :outdated, -> { where(status: "outdated") }
    scope :resolved, -> { where(status: "resolved") }

    def resolve!
      update!(status: "resolved", resolved_at: Time.current, resolved_by: Changeset::Current.actor)
    end

    def reopen!
      update!(status: "open", resolved_at: nil, resolved_by: nil)
    end

    def mark_outdated!
      update!(status: "outdated", resolved_at: nil, resolved_by: nil)
    end

    private

    def assign_review_from_document
      self.review ||= document&.review
    end

    def normalize_metadata
      self.metadata = metadata.deep_stringify_keys if metadata.is_a?(Hash)
    end

    def anchor_line_must_match_side
      return if side.blank?
      return if side == "old" && old_line.present?
      return if side == "new" && new_line.present?

      errors.add(:base, "must include a #{side} line anchor")
    end

    def document_must_belong_to_review
      return if review.blank? || document.blank?
      return if document.review_id == review_id

      errors.add(:document, "must belong to the same review")
    end

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
