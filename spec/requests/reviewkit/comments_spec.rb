# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit comments", type: :request do
  let(:reviewer) { create(:reviewer) }

  before do
    Reviewkit.configure do |config|
      config.current_actor = ->(_controller) { reviewer }
    end
  end

  it "adds a reply to an existing thread" do
    thread = create(:reviewkit_review_thread)
    create(:reviewkit_comment, review_thread: thread, body: "First pass feedback.")

    expect do
      post "/reviewkit/review_threads/#{thread.id}/comments",
           params: { comment: { body: "Follow-up: let's keep the guard clause." } },
           headers: turbo_stream_headers
    end.to change(Reviewkit::Comment, :count).by(1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include("Follow-up: let's keep the guard clause.")
    expect(Reviewkit::Comment.last.author).to eq(reviewer)
  end

  it "renders the edit form and updates a comment inside its turbo frame" do
    thread = create(:reviewkit_review_thread)
    comment = create(:reviewkit_comment, review_thread: thread, author: reviewer, body: "Original note.")
    frame_id = ActionView::RecordIdentifier.dom_id(comment)

    get "/reviewkit/review_threads/#{thread.id}/comments/#{comment.id}/edit",
        headers: { "Turbo-Frame" => frame_id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit comment")

    patch "/reviewkit/review_threads/#{thread.id}/comments/#{comment.id}",
          params: { comment: { body: "Updated note." } },
          headers: { "Turbo-Frame" => frame_id }

    expect(response).to have_http_status(:ok)
    expect(comment.reload.body).to eq("Updated note.")
    expect(response.body).to include("Updated note.")
  end

  it "deletes the last comment by removing the entire thread bucket" do
    thread = create(:reviewkit_review_thread)
    comment = create(:reviewkit_comment, review_thread: thread, author: reviewer, body: "Remove this thread.")

    expect do
      delete "/reviewkit/review_threads/#{thread.id}/comments/#{comment.id}",
             headers: turbo_stream_headers
    end.to change(Reviewkit::ReviewThread, :count).by(-1)
      .and change(Reviewkit::Comment, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
  end
end
