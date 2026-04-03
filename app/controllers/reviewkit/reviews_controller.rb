# frozen_string_literal: true

module Reviewkit
  class ReviewsController < ApplicationController
    before_action :set_review, only: %i[show edit update approve reject destroy]
    before_action :set_review_display_state, only: %i[show edit update approve reject]
    before_action :set_thread_index, only: %i[show edit update approve reject]

    def index
      @reviews = reviews_scope.includes(*review_index_includes)
      authorize_reviewkit!(:index, Review)
    end

    def show
      authorize_reviewkit!(:show, @review)
    end

    def edit
      authorize_reviewkit!(:edit_review, @review)
      @editing_review = true
      render :show
    end

    def update
      authorize_reviewkit!(:update_review, @review)

      if @review.update(review_params)
        redirect_to review_redirect_path(@review), status: :see_other, notice: "Review updated."
      else
        @editing_review = true
        render :show, status: :unprocessable_content
      end
    end

    def approve
      authorize_reviewkit!(:approve, @review)
      transition_review!(:approve!, :notice, "Review approved.")
    end

    def reject
      authorize_reviewkit!(:reject, @review)
      transition_review!(:reject!, :alert, "Review rejected.")
    end

    def destroy
      authorize_reviewkit!(:destroy, @review)
      @review.destroy!

      redirect_to reviews_index_path, status: :see_other, notice: "Review deleted."
    end

    protected

    def reviews_scope
      Review.order(updated_at: :desc)
    end

    def review_scope
      Review.includes(review_includes)
    end

    def review_index_includes
      [ :documents, :review_threads ]
    end

    def review_includes
      [ { documents: { review_threads: :comments } }, { review_threads: :comments } ]
    end

    def permitted_review_attributes
      %i[title description]
    end

    def review_redirect_path(review)
      review_path(review, document_id: @selected_document&.id, view: @view_mode)
    end

    def reviews_index_path
      reviews_path
    end

    def review_transition_failure_message(review)
      review.errors.full_messages.to_sentence.presence || "Unable to update the review."
    end

    private

    def set_review
      @review = review_scope.find(params[:id])
    end

    def set_review_display_state
      @view_mode = permitted_view_mode
      @selected_document = selected_document
      @open_thread_line_code = params[:open_thread].presence
      @open_thread_side = permitted_thread_side
    end

    def permitted_view_mode
      params[:view] == "unified" ? "unified" : "split"
    end

    def selected_document
      requested_document = review_documents_scope.find_by(id: params[:document_id]) if params[:document_id].present?
      requested_document || review_documents_scope.first
    end

    def permitted_thread_side
      return "old" if params[:thread_side] == "old"
      return "new" if params[:thread_side] == "new"

      nil
    end

    def set_thread_index
      @thread_index = selected_document_threads_scope.group_by { |thread| [ thread.document_id, thread.line_code ] }
    end

    def review_params
      params.require(:review).permit(*permitted_review_attributes)
    end

    def transition_review!(method_name, flash_type, message)
      @review.public_send(method_name)
      redirect_to review_redirect_path(@review), status: :see_other, flash_type => message
    rescue ActiveRecord::RecordInvalid => error
      @review = error.record
      flash.now[:alert] = review_transition_failure_message(@review)
      render :show, status: :unprocessable_content
    end

    def review_documents_scope
      @review.documents
    end

    def selected_document_threads_scope
      @review.review_threads.includes(:comments)
             .where(document: @selected_document)
             .order(:created_at)
    end
  end
end
