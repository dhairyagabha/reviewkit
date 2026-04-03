# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit authorization", type: :request do
  before do
    Reviewkit.configure do |config|
      config.authorize_action = ->(_controller, action, _record = nil, **_context) { action == :index }
    end
  end

  it "redirects forbidden HTML requests" do
    review = create(:reviewkit_review)

    get "/reviewkit/reviews/#{review.id}"

    expect(response).to have_http_status(:found)
  end

  it "returns forbidden for Turbo Stream comment actions" do
    thread = create(:reviewkit_review_thread)

    post "/reviewkit/review_threads/#{thread.id}/comments",
         params: { comment: { body: "Forbidden comment" } },
         headers: turbo_stream_headers

    expect(response).to have_http_status(:forbidden)
  end
end
