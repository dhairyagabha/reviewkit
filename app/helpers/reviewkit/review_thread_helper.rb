# frozen_string_literal: true

module Reviewkit
  module ReviewThreadHelper
    def reviewkit_actor_label(actor)
      return "System" unless actor
      return actor.name if actor.respond_to?(:name) && actor.name.present?
      return actor.email if actor.respond_to?(:email) && actor.email.present?

      actor.to_s
    end

    def reviewkit_thread_bucket_id(document, line_code)
      "reviewkit-document-#{document.id}-line-#{line_code}"
    end

    def reviewkit_thread_bucket_row_id(document, line_code)
      "#{reviewkit_thread_bucket_id(document, line_code)}-row"
    end

    def reviewkit_threads_for(thread_index, document, row)
      Array(thread_index[[ document.id, row.fetch("line_code") ]])
    end

    def reviewkit_thread_starter_comment(thread)
      thread.comments.min_by { |comment| [ comment.created_at, comment.id ] }
    end

    def reviewkit_thread_preview(thread)
      truncate(reviewkit_thread_starter_comment(thread)&.body.to_s, length: 120)
    end

    def reviewkit_thread_manageable?(thread)
      starter_comment = reviewkit_thread_starter_comment(thread)
      return false unless starter_comment

      reviewkit_comment_manageable?(starter_comment)
    end

    def reviewkit_comment_manageable?(comment)
      comment.author == reviewkit_current_actor
    end

    def reviewkit_comment_destroyable?(comment)
      return false unless reviewkit_comment_manageable?(comment)

      comment.review_thread.comments.size > 1 || comment.review_thread.comments.first == comment
    end

    def reviewkit_comment_edited?(comment)
      comment.updated_at.present? && comment.created_at.present? && comment.updated_at > comment.created_at
    end
  end
end
