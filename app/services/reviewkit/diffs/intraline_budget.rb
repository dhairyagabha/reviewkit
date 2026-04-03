# frozen_string_literal: true

module Reviewkit
  module Diffs
    class IntralineBudget
      def self.allow?(...)
        new(...).allow?
      end

      def initialize(old_text:, new_text:, review_document_count: nil, changed_row_count: nil, limits: Reviewkit.config.intraline_limits)
        @old_text = old_text.to_s
        @new_text = new_text.to_s
        @review_document_count = review_document_count
        @changed_row_count = changed_row_count
        @limits = limits
      end

      def allow?
        return false unless @limits.enabled
        return false if exceeds_limit?(@review_document_count, @limits.max_review_files)
        return false if exceeds_limit?(@changed_row_count, @limits.max_changed_lines)
        return false if exceeds_line_length_limit?

        true
      end

      private

      def exceeds_limit?(value, limit)
        value.present? && limit.present? && value > limit
      end

      def exceeds_line_length_limit?
        return false unless @limits.max_line_length.present?

        [ @old_text.length, @new_text.length ].max > @limits.max_line_length
      end
    end
  end
end
