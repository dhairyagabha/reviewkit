# frozen_string_literal: true

module Changeset
  class CommentsController < ApplicationController
    before_action :set_thread
    before_action :set_comment, only: %i[show edit update destroy]

    def create
      authorize_changeset!(:comment, @thread.review)

      @comment = @thread.comments.build(comment_attributes.merge(author: changeset_current_actor, metadata: {}))

      @comment.save

      render_thread_bucket(status: @comment.persisted? ? :ok : :unprocessable_content)
    end

    def show
      authorize_changeset!(:show, @thread.review)
      render_comment_frame
    end

    def edit
      authorize_comment_management!(:edit_comment)
      render_edit_frame
    end

    def update
      authorize_comment_management!(:update_comment)

      if @comment.update(comment_attributes)
        render_comment_frame
      else
        render_edit_frame(status: :unprocessable_content)
      end
    end

    def destroy
      authorize_comment_management!(:destroy_comment)

      if @thread.comments.size == 1
        @thread.destroy!
      else
        @comment.destroy!
      end

      render_thread_bucket(status: :ok)
    end

    protected

    def review_thread_scope
      ReviewThread.includes(:review, :document, :comments)
    end

    def comment_scope(thread)
      thread.comments
    end

    def permitted_comment_attributes
      %i[body]
    end

    def comment_request_attributes
      %i[frame_id view]
    end

    def comment_frame_redirect_path(comment)
      review_path(comment.review_thread.review, anchor: helpers.changeset_document_anchor(comment.review_thread.document))
    end

    private

    def set_thread
      @thread = review_thread_scope.find(params[:review_thread_id])
    end

    def set_comment
      @comment = comment_scope(@thread).find(params[:id])
    end

    def comment_params
      params.fetch(:comment, ActionController::Parameters.new).permit(*(permitted_comment_attributes + comment_request_attributes))
    end

    def comment_attributes
      comment_params.to_h.symbolize_keys.slice(*permitted_comment_attributes)
    end

    def authorize_comment_management!(action)
      authorize_changeset!(action, @comment)
      raise Changeset::AuthorizationError, "Forbidden action: #{action}" unless comment_manageable?(@comment)
    end

    def comment_manageable?(comment)
      comment.author == changeset_current_actor
    end

    def render_comment_frame(status: :ok)
      if changeset_frame_request?
        render partial: "changeset/comments/comment", locals: { comment: @comment }, status: status
      else
        redirect_to comment_frame_redirect_path(@comment)
      end
    end

    def render_edit_frame(status: :ok)
      if changeset_frame_request?
        render partial: "changeset/comments/edit_form", locals: { comment: @comment }, status: status
      else
        redirect_to comment_frame_redirect_path(@comment)
      end
    end

    def render_thread_bucket(status:)
      @review = @thread.review
      @document = @thread.document
      @row = @document.diff_rows.find { |row| row.fetch("line_code") == @thread.line_code }
      @threads = @review.review_threads.includes(:comments)
                        .where(document: @document, line_code: @thread.line_code)
                        .order(:created_at)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: ::Turbo::Streams::TagBuilder.new(view_context).replace(
            helpers.changeset_thread_bucket_row_id(@document, @thread.line_code),
            partial: "changeset/review_threads/bucket_row",
            locals: {
              colspan: comment_params[:view] == "unified" ? 4 : 6,
              composer_open: false,
              composer_side: nil,
              document: @document,
              frame_id: comment_params[:frame_id].presence || helpers.dom_id(@review, :review),
              line_code: @thread.line_code,
              review: @review,
              row: @row,
              thread_errors: @comment&.errors&.full_messages || [],
              threads: @threads,
              view_mode: comment_params[:view] == "unified" ? "unified" : "split"
            }
          ), status: status
        end
        format.html { redirect_to review_path(@review, anchor: helpers.changeset_document_anchor(@document)) }
      end
    end
  end
end
