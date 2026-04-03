# frozen_string_literal: true

module Changeset
  class ReviewThreadsController < ApplicationController
    before_action :set_review, only: :create
    before_action :set_thread, only: %i[show edit update destroy resolve reopen mark_outdated]

    def create
      authorize_changeset!(:comment, @review)

      document = review_documents_scope.find(review_thread_params.fetch(:document_id))

      ReviewThread.transaction do
        @thread = @review.review_threads.build(
          build_review_thread_attributes(document)
        )
        @thread.save!

        @thread.comments.create!(
          author: changeset_current_actor,
          body: starter_comment_body,
          metadata: {}
        )
      end

      render_thread_row(document, @thread.line_code)
    rescue ActiveRecord::RecordInvalid => error
      render_thread_row(
        document,
        review_thread_params.fetch(:line_code),
        status: :unprocessable_content,
        thread_errors: error.record.errors.full_messages,
        composer_open: true,
        composer_side: review_thread_params[:side]
      )
    end

    def show
      authorize_changeset!(:show, @thread.review)
      render_thread_frame
    end

    def edit
      authorize_thread_management!(:edit_thread)
      render_edit_frame
    end

    def update
      authorize_thread_management!(:update_thread)

      if starter_comment.update(thread_params)
        @thread.reload
        render_thread_frame
      else
        render_edit_frame(status: :unprocessable_content)
      end
    end

    def destroy
      authorize_thread_management!(:destroy_thread)
      document = @thread.document
      line_code = @thread.line_code
      @thread.destroy!

      render_thread_row(document, line_code)
    end

    def resolve
      authorize_changeset!(:resolve, @thread)
      @thread.resolve!
      render_thread_row(@thread.document, @thread.line_code)
    end

    def reopen
      authorize_changeset!(:reopen, @thread)
      @thread.reopen!
      render_thread_row(@thread.document, @thread.line_code)
    end

    def mark_outdated
      authorize_changeset!(:update_thread_status, @thread)
      @thread.mark_outdated!
      render_thread_row(@thread.document, @thread.line_code)
    end

    protected

    def review_scope
      Review.all
    end

    def review_thread_scope
      ReviewThread.includes(:review, :document, :comments)
    end

    def permitted_review_thread_attributes
      []
    end

    def review_thread_request_attributes
      %i[
        body
        document_id
        frame_id
        line_code
        new_line
        new_text
        old_line
        old_text
        side
        view
      ]
    end

    def permitted_review_thread_update_attributes
      %i[body]
    end

    def review_documents_scope
      @review.documents
    end

    def build_review_thread_attributes(document)
      {
        document:,
        line_code: review_thread_params.fetch(:line_code),
        metadata: line_metadata,
        new_line: integer_or_nil(review_thread_params[:new_line]),
        old_line: integer_or_nil(review_thread_params[:old_line]),
        side: review_thread_params.fetch(:side)
      }.merge(review_thread_model_attributes)
    end

    def thread_redirect_path(thread)
      review_path(thread.review, anchor: helpers.changeset_document_anchor(thread.document))
    end

    def thread_row_redirect_path(review, document, line_code:, composer_open:, composer_side:)
      review_path(
        review,
        document_id: document.id,
        open_thread: composer_open ? line_code : nil,
        thread_side: composer_side,
        view: view_mode
      )
    end

    private

    def set_review
      @review = review_scope.find(params[:review_id])
    end

    def set_thread
      @thread = review_thread_scope.find(params[:id])
    end

    def starter_comment
      @starter_comment ||= @thread.comments.order(:created_at, :id).first!
    end

    def review_thread_params
      params.require(:review_thread).permit(*(review_thread_request_attributes + permitted_review_thread_attributes))
    end

    def thread_params
      params.require(:review_thread).permit(*permitted_review_thread_update_attributes)
    end

    def review_thread_model_attributes
      review_thread_params.to_h.symbolize_keys.slice(*permitted_review_thread_attributes)
    end

    def starter_comment_body
      review_thread_params.fetch(:body)
    end

    def integer_or_nil(value)
      value.present? ? value.to_i : nil
    end

    def line_metadata
      {
        "old_text" => review_thread_params[:old_text].to_s,
        "new_text" => review_thread_params[:new_text].to_s
      }
    end

    def authorize_thread_management!(action)
      authorize_changeset!(action, @thread)
      raise Changeset::AuthorizationError, "Forbidden action: #{action}" unless helpers.changeset_thread_manageable?(@thread)
    end

    def render_thread_frame(status: :ok)
      if changeset_frame_request?
        render partial: "changeset/review_threads/thread",
               locals: {
                 frame_id: requested_frame_id(@thread.review),
                 review: @thread.review,
                 thread: @thread,
                 view_mode: view_mode
               },
               status: status
      else
        redirect_to thread_redirect_path(@thread)
      end
    end

    def render_edit_frame(status: :ok)
      if changeset_frame_request?
        render partial: "changeset/review_threads/edit_form",
               locals: {
                 comment: starter_comment,
                 frame_id: requested_frame_id(@thread.review),
                 review: @thread.review,
                 thread: @thread,
                 view_mode: view_mode
               },
               status: status
      else
        redirect_to thread_redirect_path(@thread)
      end
    end

    def render_thread_row(document, line_code, status: :ok, thread_errors: [], composer_open: false, composer_side: nil)
      review = document.review
      row = document.diff_rows.find { |diff_row| diff_row.fetch("line_code") == line_code }
      threads = review.review_threads.includes(:comments)
                      .where(document: document, line_code: line_code)
                      .order(:created_at)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: ::Turbo::Streams::TagBuilder.new(view_context).replace(
            helpers.changeset_thread_bucket_row_id(document, line_code),
            partial: "changeset/review_threads/bucket_row",
            locals: {
              colspan: view_mode == "unified" ? 4 : 6,
              composer_open: composer_open || thread_errors.present?,
              composer_side: composer_side,
              document: document,
              frame_id: requested_frame_id(review),
              line_code: line_code,
              review: review,
              row: row,
              thread_errors: thread_errors,
              threads: threads,
              view_mode: view_mode
            }
          ), status: status
        end
        format.html do
          redirect_to thread_row_redirect_path(
            review,
            document,
            line_code:,
            composer_open: composer_open || thread_errors.present?,
            composer_side:
          )
        end
      end
    end

    def requested_frame_id(review)
      params[:frame_id].presence || request_review_thread_param(:frame_id).presence || helpers.dom_id(review, :review)
    end

    def view_mode
      requested_view = params[:view].presence || request_review_thread_param(:view).presence
      requested_view == "unified" ? "unified" : "split"
    end

    def request_review_thread_param(key)
      review_thread_params[key] if params[:review_thread].present?
    end
  end
end
