# frozen_string_literal: true

module Reviewkit
  module Reviews
    class Create
      def self.call(...)
        new(...).call
      end

      def initialize(title:, description: nil, creator: nil, reviewable: nil, external_reference: nil, metadata: {}, review_attributes: {}, status: "draft", documents: [])
        @title = title
        @description = description
        @creator = creator
        @reviewable = reviewable
        @external_reference = external_reference
        @metadata = metadata
        @review_attributes = review_attributes
        @status = status
        @documents = documents
      end

      def call
        Reviewkit::Current.set(actor: @creator, source: self.class.name) do
          Review.transaction do
            review = Review.new(
              {
                title: @title,
                description: @description,
                status: @status,
                external_reference: @external_reference,
                metadata: @metadata,
                reviewable: @reviewable
              }.merge(@review_attributes)
            )
            review.creator = @creator
            review.save!

            @documents.each_with_index do |document, index|
              payload = document.to_h.with_indifferent_access
              review.documents.create!(
                intraline_review_document_count: @documents.size,
                path: payload.fetch(:path),
                language: payload.fetch(:language, "plaintext"),
                old_content: payload.fetch(:old_content, ""),
                new_content: payload.fetch(:new_content, ""),
                metadata: payload.fetch(:metadata, {}),
                position: payload.fetch(:position, index)
              )
            end

            review
          end
        end
      end
    end
  end
end
