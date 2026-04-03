# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit reviews", type: :request do
  let(:reviewer) { create(:reviewer) }

  before do
    Reviewkit.configure do |config|
      config.current_actor = ->(_controller) { reviewer }
    end
  end

  it "renders the review index" do
    create(:reviewkit_review, title: "Feature review")

    get "/reviewkit/reviews"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Feature review")
    expect(response.body).to include("Reviews")
    expect(response.body).to include("Filter reviews by title, reference, or description")
    expect(response.body).to include("data-controller=\"reviewkit--review-index\"")
    expect(response.body).to include("<table")
    expect(response.body).to include('type="importmap"')
    expect(response.body).to include('import "reviewkit/application"')
    expect(response.body.index('type="importmap"')).to be < response.body.index('import "reviewkit/application"')
  end

  it "renders the Git-style review page with metadata and threads" do
    review = create(:reviewkit_review, title: "Checkout hardening review", external_reference: "PR-77")
    document = create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")
    thread = create(:reviewkit_review_thread, review:, document:)
    comment = create(:reviewkit_comment, review_thread: thread, author: reviewer, body: "This change needs a null check.")

    get "/reviewkit/reviews/#{review.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Checkout hardening review")
    expect(response.body).to include(review.description)
    expect(response.body).to include("app/services/checkouts/submit_order.rb")
    expect(response.body).to include("pull_request")
    expect(response.body).to include("This change needs a null check.")
    expect(response.body).to include("Jump to file")
    expect(response.body).to include('data-controller="reviewkit--file-nav"')
    expect(response.body).to include("Approve")
    expect(response.body).to include("Unified")
    expect(response.body).to include("aria-label=\"Edit review\"")
    expect(response.body).to include("aria-label=\"Delete review\"")
    expect(response.body).to include(%(id="reviewkit-document-#{document.id}-line-#{thread.line_code}-row"))
    expect(response.body).to include(%(data-turbo-frame="#{ActionView::RecordIdentifier.dom_id(thread)}"))
    expect(response.body).to include(%(data-turbo-frame="#{ActionView::RecordIdentifier.dom_id(comment)}"))
    expect(response.body).to include("reviewkit-inline-change--new")
  end

  it "renders a review inside a turbo frame without the full page shell" do
    review = create(:reviewkit_review, title: "Embedded review")
    create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")

    get "/reviewkit/reviews/#{review.id}", headers: { "Turbo-Frame" => "review_frame" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('turbo-frame id="review_frame"')
    expect(response.body).to include("Embedded review")
    expect(response.body).not_to include('type="importmap"')
    expect(response.body).not_to include("<html")
  end

  it "wraps a review in the requested frame when the frame id is passed as a param" do
    review = create(:reviewkit_review, title: "Embedded review")
    create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")

    get "/reviewkit/reviews/#{review.id}", params: { reviewkit_frame_id: "review_frame" }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('turbo-frame id="review_frame"')
    expect(response.body).to include("Embedded review")
    expect(response.body).not_to include("<html")
  end

  it "renders only the requested document and supports unified diff mode" do
    review = create(:reviewkit_review)
    create(:reviewkit_document, review:, path: "app/models/order.rb")
    selected_document = create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")

    get "/reviewkit/reviews/#{review.id}", params: { document_id: selected_document.id, view: "unified" }

    expect(response).to have_http_status(:ok)
    expect(response.body.scan("reviewkit-file-header").size).to eq(1)
    expect(response.body).to include("reviewkit-diff-table--unified")
    expect(response.body).to include("app/services/checkouts/submit_order.rb")
    expect(response.body).to include("reviewkit-inline-change--new")
  end

  it "renders inline highlights for reviews created before intraline diff caching existed" do
    review = create(:reviewkit_review, title: "Legacy cached review")
    document = create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")
    legacy_cache = document.diff_cache.deep_dup
    legacy_cache.fetch("rows").each { |row| row.delete("inline_changes") }
    document.update_column(:diff_cache, legacy_cache)

    get "/reviewkit/reviews/#{review.id}"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Legacy cached review")
    expect(response.body).to include("reviewkit-inline-change--new")
  end

  it "renders an inline edit form and updates the review" do
    review = create(:reviewkit_review, title: "Original review title", description: "Original description.")
    create(:reviewkit_document, review:, path: "app/services/checkouts/submit_order.rb")

    get "/reviewkit/reviews/#{review.id}/edit",
        params: { view: "split" },
        headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(review, :review) }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Save")
    expect(response.body).to include("Original review title")

    patch "/reviewkit/reviews/#{review.id}",
          params: {
            view: "split",
            review: {
              title: "Updated review title",
              description: "Updated description."
            }
          },
          headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(review, :review) }

    expect(response).to have_http_status(:see_other)
    expect(review.reload.title).to eq("Updated review title")
    expect(review.description).to eq("Updated description.")
  end

  it "permits host-app review attributes through controller extensions" do
    review = create(:reviewkit_review, review_type: "code")
    create(:reviewkit_document, review: review, path: "app/services/checkouts/submit_order.rb")

    patch "/reviewkit/reviews/#{review.id}",
          params: {
            review: {
              title: review.title,
              description: review.description,
              review_type: "content"
            }
          }

    expect(response).to have_http_status(:see_other)
    expect(review.reload.review_type).to eq("content")
  end

  it "approves and rejects a review" do
    review = create(:reviewkit_review, status: "open")

    patch "/reviewkit/reviews/#{review.id}/approve"

    expect(response).to have_http_status(:see_other)
    expect(review.reload).to be_approved
    expect(flash[:notice]).to eq("Review approved.")

    patch "/reviewkit/reviews/#{review.id}/reject"

    expect(response).to have_http_status(:see_other)
    expect(review.reload).to be_rejected
    expect(flash[:alert]).to eq("Review rejected.")
  end

  it "runs host-app model callbacks when the review status changes" do
    review = create(:reviewkit_review, status: "open", review_type: "content")

    patch "/reviewkit/reviews/#{review.id}/approve"

    expect(response).to have_http_status(:see_other)
    expect(Reviewkit::Review.host_status_transitions.last).to include(
      id: review.id,
      previous_status: "open",
      review_type: "content",
      status: "approved"
    )
  end

  it "blocks approval when open threads remain" do
    review = create(:reviewkit_review, status: "open")
    document = create(:reviewkit_document, review:)
    create(:reviewkit_review_thread, review:, document:, status: "open")

    patch "/reviewkit/reviews/#{review.id}/approve",
          headers: { "Turbo-Frame" => ActionView::RecordIdentifier.dom_id(review, :review) }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Status cannot change while open threads remain")
    expect(review.reload.status).to eq("open")
  end

  it "deletes a review" do
    review = create(:reviewkit_review)

    expect do
      delete "/reviewkit/reviews/#{review.id}"
    end.to change(Reviewkit::Review, :count).by(-1)

    expect(response).to have_http_status(:see_other)
  end
end
