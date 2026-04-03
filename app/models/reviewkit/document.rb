# frozen_string_literal: true

module Reviewkit
  class Document < ApplicationRecord
    attr_accessor :intraline_review_document_count

    enum :status, {
      added: "added",
      removed: "removed",
      modified: "modified",
      unchanged: "unchanged"
    }, validate: true

    belongs_to :review, inverse_of: :documents
    has_many :review_threads, dependent: :destroy, inverse_of: :document

    validates :language, presence: true
    validates :path, presence: true
    validates :position, numericality: { greater_than_or_equal_to: 0 }
    validates :path, uniqueness: { scope: :review_id }
    validate :metadata_must_be_hash

    before_validation :assign_status
    before_validation :refresh_diff_cache
    before_validation :normalize_metadata

    def additions_count
      diff_cache.dig("stats", "additions").to_i
    end

    def deletions_count
      diff_cache.dig("stats", "deletions").to_i
    end

    def diff_rows
      Array(diff_cache["rows"])
    end

    private

    def assign_status
      self.status =
        if old_content.blank? && new_content.present?
          "added"
        elsif old_content.present? && new_content.blank?
          "removed"
        elsif old_content == new_content
          "unchanged"
        else
          "modified"
        end
    end

    def refresh_diff_cache
      self.diff_cache = Reviewkit::Diffs::SplitDiff.call(
        old_content: old_content.to_s,
        new_content: new_content.to_s,
        review_document_count: resolved_review_document_count
      )
    end

    def resolved_review_document_count
      return intraline_review_document_count if intraline_review_document_count.present?
      return unless review

      review.documents.size
    end

    def normalize_metadata
      self.metadata = metadata.deep_stringify_keys if metadata.is_a?(Hash)
    end

    def metadata_must_be_hash
      return if metadata.nil? || metadata.is_a?(Hash)

      errors.add(:metadata, "must be a hash")
    end
  end
end
