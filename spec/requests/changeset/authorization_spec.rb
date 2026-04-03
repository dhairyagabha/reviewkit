# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Changeset authorization", type: :request do
  before do
    Changeset.configure do |config|
      config.authorize_action = ->(_controller, action, _record = nil, **_context) { action == :index }
    end
  end

  it "redirects forbidden HTML requests" do
    review = create(:changeset_review)

    get "/changeset/reviews/#{review.id}"

    expect(response).to have_http_status(:found)
  end

  it "returns forbidden for Turbo Stream comment actions" do
    thread = create(:changeset_review_thread)

    post "/changeset/review_threads/#{thread.id}/comments",
         params: { comment: { body: "Forbidden comment" } },
         headers: turbo_stream_headers

    expect(response).to have_http_status(:forbidden)
  end
end
