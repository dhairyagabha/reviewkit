# frozen_string_literal: true

module Changeset
  module ReviewThreadHelper
    def changeset_actor_label(actor)
      return "System" unless actor
      return actor.name if actor.respond_to?(:name) && actor.name.present?
      return actor.email if actor.respond_to?(:email) && actor.email.present?

      actor.to_s
    end

    def changeset_thread_bucket_id(document, line_code)
      "changeset-document-#{document.id}-line-#{line_code}"
    end

    def changeset_thread_bucket_row_id(document, line_code)
      "#{changeset_thread_bucket_id(document, line_code)}-row"
    end

    def changeset_threads_for(thread_index, document, row)
      Array(thread_index[[ document.id, row.fetch("line_code") ]])
    end

    def changeset_thread_starter_comment(thread)
      thread.comments.min_by { |comment| [ comment.created_at, comment.id ] }
    end

    def changeset_thread_preview(thread)
      truncate(changeset_thread_starter_comment(thread)&.body.to_s, length: 120)
    end

    def changeset_thread_manageable?(thread)
      starter_comment = changeset_thread_starter_comment(thread)
      return false unless starter_comment

      changeset_comment_manageable?(starter_comment)
    end

    def changeset_comment_manageable?(comment)
      comment.author == changeset_current_actor
    end

    def changeset_comment_destroyable?(comment)
      return false unless changeset_comment_manageable?(comment)

      comment.review_thread.comments.size > 1 || comment.review_thread.comments.first == comment
    end

    def changeset_comment_edited?(comment)
      comment.updated_at.present? && comment.created_at.present? && comment.updated_at > comment.created_at
    end
  end
end
