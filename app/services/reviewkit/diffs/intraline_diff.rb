# frozen_string_literal: true

require "diff/lcs"

module Reviewkit
  module Diffs
    class IntralineDiff
      SIMILARITY_THRESHOLD = 0.5
      TOKEN_PATTERN = /\s+|[[:alnum:]_]+|[^[:alnum:]_\s]+/

      def self.call(...)
        new(...).call
      end

      def initialize(old_text:, new_text:)
        @old_text = old_text.to_s
        @new_text = new_text.to_s
      end

      def call
        return empty_ranges if @old_text == @new_text

        old_tokens = tokenize(@old_text)
        new_tokens = tokenize(@new_text)
        ranges = empty_ranges
        pending_old = []
        pending_new = []
        old_index = 0
        new_index = 0
        shared_non_whitespace_chars = 0

        Diff::LCS.sdiff(token_texts(old_tokens), token_texts(new_tokens)).each do |change|
          case change.action
          when "="
            shared_non_whitespace_chars += append_group_ranges(ranges, pending_old, pending_new)
            pending_old = []
            pending_new = []
            shared_non_whitespace_chars += non_whitespace_character_count(old_tokens.fetch(old_index).fetch("text"))
            old_index += 1
            new_index += 1
          when "!"
            pending_old << old_tokens.fetch(old_index)
            pending_new << new_tokens.fetch(new_index)
            old_index += 1
            new_index += 1
          when "-"
            pending_old << old_tokens.fetch(old_index)
            old_index += 1
          when "+"
            pending_new << new_tokens.fetch(new_index)
            new_index += 1
          end
        end

        shared_non_whitespace_chars += append_group_ranges(ranges, pending_old, pending_new)
        normalized_ranges = normalize_ranges(ranges)

        return normalized_ranges if meets_similarity_threshold?(shared_non_whitespace_chars)

        empty_ranges
      end

      private

      def tokenize(text)
        cursor = 0

        text.to_enum(:scan, TOKEN_PATTERN).map do
          token_text = Regexp.last_match(0)
          token = {
            "kind" => token_kind(token_text),
            "text" => token_text,
            "start" => cursor,
            "end" => cursor + token_text.length
          }
          cursor = token.fetch("end")
          token
        end
      end

      def token_texts(tokens)
        tokens.map { |token| token.fetch("text") }
      end

      def token_kind(token_text)
        return "whitespace" if token_text.match?(/\A\s+\z/)
        return "word" if token_text.match?(/\A[[:alnum:]_]+\z/)

        "punctuation"
      end

      def append_group_ranges(ranges, old_tokens, new_tokens)
        return 0 if old_tokens.empty? && new_tokens.empty?

        if old_tokens.empty?
          ranges["new"] << range_from_tokens(new_tokens)
          return 0
        end

        if new_tokens.empty?
          ranges["old"] << range_from_tokens(old_tokens)
          return 0
        end

        if refine_single_token_pair?(old_tokens, new_tokens)
          return append_character_ranges(ranges, old_tokens.first, new_tokens.first)
        end

        ranges["old"] << range_from_tokens(old_tokens)
        ranges["new"] << range_from_tokens(new_tokens)
        0
      end

      def refine_single_token_pair?(old_tokens, new_tokens)
        return false unless old_tokens.one? && new_tokens.one?

        old_token = old_tokens.first
        new_token = new_tokens.first
        return true if old_token.fetch("kind") == "whitespace" || new_token.fetch("kind") == "whitespace"
        return false unless old_token.fetch("kind") == new_token.fetch("kind")

        old_text = old_token.fetch("text")
        new_text = new_token.fetch("text")

        old_text.start_with?(new_text) ||
          new_text.start_with?(old_text) ||
          old_text.end_with?(new_text) ||
          new_text.end_with?(old_text) ||
          common_prefix_length(old_text, new_text).positive? ||
          common_suffix_length(old_text, new_text).positive?
      end

      def append_character_ranges(ranges, old_token, new_token)
        old_offset = old_token.fetch("start")
        new_offset = new_token.fetch("start")
        old_index = 0
        new_index = 0
        shared_non_whitespace_chars = 0

        Diff::LCS.sdiff(old_token.fetch("text").chars, new_token.fetch("text").chars).each do |change|
          case change.action
          when "="
            shared_non_whitespace_chars += 1 unless change.old_element.match?(/\s/)
            old_index += 1
            new_index += 1
          when "!"
            ranges["old"] << build_range(old_offset + old_index, old_offset + old_index + 1)
            ranges["new"] << build_range(new_offset + new_index, new_offset + new_index + 1)
            old_index += 1
            new_index += 1
          when "-"
            ranges["old"] << build_range(old_offset + old_index, old_offset + old_index + 1)
            old_index += 1
          when "+"
            ranges["new"] << build_range(new_offset + new_index, new_offset + new_index + 1)
            new_index += 1
          end
        end

        shared_non_whitespace_chars
      end

      def range_from_tokens(tokens)
        build_range(tokens.first.fetch("start"), tokens.last.fetch("end"))
      end

      def normalize_ranges(ranges)
        {
          "old" => merge_ranges(Array(ranges["old"])),
          "new" => merge_ranges(Array(ranges["new"]))
        }
      end

      def merge_ranges(ranges)
        ranges
          .map { |range| build_range(range.fetch("start"), range.fetch("end")) }
          .reject { |range| range.fetch("start") >= range.fetch("end") }
          .sort_by { |range| [ range.fetch("start"), range.fetch("end") ] }
          .each_with_object([]) do |range, merged|
            if merged.empty? || range.fetch("start") > merged.last.fetch("end")
              merged << range
            else
              merged.last["end"] = [ merged.last.fetch("end"), range.fetch("end") ].max
            end
          end
      end

      def build_range(start_index, end_index)
        { "start" => start_index, "end" => end_index }
      end

      def meets_similarity_threshold?(shared_non_whitespace_chars)
        denominator = [
          non_whitespace_character_count(@old_text),
          non_whitespace_character_count(@new_text)
        ].max

        return true if denominator.zero?

        (shared_non_whitespace_chars.to_f / denominator) >= SIMILARITY_THRESHOLD
      end

      def non_whitespace_character_count(text)
        text.each_char.count { |character| !character.match?(/\s/) }
      end

      def common_prefix_length(old_text, new_text)
        old_text.chars.zip(new_text.chars).take_while { |old_char, new_char| old_char == new_char }.size
      end

      def common_suffix_length(old_text, new_text)
        old_text.chars.reverse.zip(new_text.chars.reverse).take_while { |old_char, new_char| old_char == new_char }.size
      end

      def empty_ranges
        { "old" => [], "new" => [] }
      end
    end
  end
end
