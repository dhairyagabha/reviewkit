# frozen_string_literal: true

module Reviewkit
  module FrameHelper
    def reviewkit_requested_frame_id
      request.headers["Turbo-Frame"].presence || params[:reviewkit_frame_id].presence
    end

    def reviewkit_frame_request?
      reviewkit_requested_frame_id.present?
    end

    def reviewkit_wrap_in_frame(&block)
      content = capture(&block)
      frame_id = reviewkit_requested_frame_id
      return content if frame_id.blank?

      turbo_frame_tag(frame_id) { content }
    end

    def reviewkit_document_anchor(document)
      "document-#{document.id}"
    end

    def reviewkit_review_frame_id(review)
      reviewkit_requested_frame_id.presence || dom_id(review, :review)
    end

    def reviewkit_document_path_parts(document_or_path)
      path = document_or_path.respond_to?(:path) ? document_or_path.path.to_s : document_or_path.to_s
      directory = File.dirname(path)
      directory = nil if directory.blank? || directory == "."

      [ directory ? "#{directory}/" : nil, File.basename(path) ]
    end
  end
end
