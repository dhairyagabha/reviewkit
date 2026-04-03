# frozen_string_literal: true

module Changeset
  module FrameHelper
    def changeset_requested_frame_id
      request.headers["Turbo-Frame"].presence || params[:changeset_frame_id].presence
    end

    def changeset_frame_request?
      changeset_requested_frame_id.present?
    end

    def changeset_wrap_in_frame(&block)
      content = capture(&block)
      frame_id = changeset_requested_frame_id
      return content if frame_id.blank?

      turbo_frame_tag(frame_id) { content }
    end

    def changeset_document_anchor(document)
      "document-#{document.id}"
    end

    def changeset_review_frame_id(review)
      changeset_requested_frame_id.presence || dom_id(review, :review)
    end

    def changeset_document_path_parts(document_or_path)
      path = document_or_path.respond_to?(:path) ? document_or_path.path.to_s : document_or_path.to_s
      directory = File.dirname(path)
      directory = nil if directory.blank? || directory == "."

      [ directory ? "#{directory}/" : nil, File.basename(path) ]
    end
  end
end
