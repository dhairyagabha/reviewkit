# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit review threads", type: :request do
  let(:reviewer) { create(:reviewer) }
  let(:review) { create(:reviewkit_review) }
  let(:document) { create(:reviewkit_document, review:) }
  let(:row) { document.diff_rows.detect { |diff_row| diff_row["kind"] != "context" } || document.diff_rows.first }

  before do
    Reviewkit.configure do |config|
      config.current_actor = ->(_controller) { reviewer }
    end
  end

  it "creates a new thread with its first comment" do
    expect do
      post "/reviewkit/reviews/#{review.id}/threads",
           params: {
             review_thread: {
               body: "Prefer the data layer push here.",
               document_id: document.id,
               line_code: row.fetch("line_code"),
               side: row["new_line"].present? ? "new" : "old",
               old_line: row["old_line"],
               new_line: row["new_line"],
               old_text: row["old_text"],
               new_text: row["new_text"]
             }
           },
           headers: turbo_stream_headers
    end.to change(Reviewkit::ReviewThread, :count).by(1)
      .and change(Reviewkit::Comment, :count).by(1)

    thread = Reviewkit::ReviewThread.last

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    expect(response.body).to include("Prefer the data layer push here.")
    expect(response.body).to include(%(target="reviewkit-document-#{document.id}-line-#{row.fetch("line_code")}-row"))
    expect(thread.comments.first.author).to eq(reviewer)
    expect(thread.metadata).to include("old_text" => row["old_text"], "new_text" => row["new_text"])
  end

  it "returns validation errors without losing the diff anchor context" do
    post "/reviewkit/reviews/#{review.id}/threads",
         params: {
           review_thread: {
             body: "",
             document_id: document.id,
             line_code: row.fetch("line_code"),
             side: row["new_line"].present? ? "new" : "old",
             old_line: row["old_line"],
             new_line: row["new_line"],
             old_text: row["old_text"],
             new_text: row["new_text"]
           }
         },
         headers: turbo_stream_headers

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Body can&#39;t be blank")
    expect(response.body).to include(row["new_text"].presence || row["old_text"])
  end

  it "resolves and reopens a thread" do
    thread = create(:reviewkit_review_thread, review:, document:)
    create(:reviewkit_comment, review_thread: thread, body: "Please add a guard clause.")

    patch "/reviewkit/review_threads/#{thread.id}/resolve", headers: turbo_stream_headers

    expect(response).to have_http_status(:ok)
    expect(thread.reload.status).to eq("resolved")
    expect(thread.resolved_by).to eq(reviewer)

    patch "/reviewkit/review_threads/#{thread.id}/reopen", headers: turbo_stream_headers

    expect(response).to have_http_status(:ok)
    expect(thread.reload.status).to eq("open")
  end

  it "marks a thread outdated" do
    thread = create(:reviewkit_review_thread, review:, document:)
    create(:reviewkit_comment, review_thread: thread, author: reviewer, body: "This line will be superseded.")

    patch "/reviewkit/review_threads/#{thread.id}/mark_outdated", headers: turbo_stream_headers

    expect(response).to have_http_status(:ok)
    expect(thread.reload.status).to eq("outdated")
  end

  it "renders an inline thread edit form, updates the starter comment, and deletes the thread" do
    thread = create(:reviewkit_review_thread, review:, document:)
    starter_comment = create(:reviewkit_comment, review_thread: thread, author: reviewer, body: "Original thread note.")
    frame_id = ActionView::RecordIdentifier.dom_id(thread)

    get "/reviewkit/review_threads/#{thread.id}/edit",
        headers: { "Turbo-Frame" => frame_id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Edit thread")

    patch "/reviewkit/review_threads/#{thread.id}",
          params: { review_thread: { body: "Updated thread note." } },
          headers: { "Turbo-Frame" => frame_id }

    expect(response).to have_http_status(:ok)
    expect(starter_comment.reload.body).to eq("Updated thread note.")
    expect(response.body).to include("Updated thread note.")

    expect do
      delete "/reviewkit/review_threads/#{thread.id}",
             params: { view: "split" },
             headers: turbo_stream_headers
    end.to change(Reviewkit::ReviewThread, :count).by(-1)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(%(id="reviewkit-document-#{document.id}-line-#{thread.line_code}-row"))
  end
end
