# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit lifecycle notifications", type: :model do
  self.use_transactional_tests = false

  around do |example|
    Reviewkit::Current.reset
    example.run
  ensure
    Reviewkit::Current.reset
    Reviewkit::Comment.delete_all
    Reviewkit::ReviewThread.delete_all
    Reviewkit::Document.delete_all
    Reviewkit::Review.delete_all
    Reviewer.delete_all
  end

  it "publishes create and status change notifications for reviews" do
    reviewer = create(:reviewer)
    review = nil
    events = capture_reviewkit_events("reviewkit.review.created", "reviewkit.review.status_changed") do
      review = Reviewkit::Current.set(actor: reviewer, source: "spec") do
        create(:reviewkit_review, creator: reviewer, status: "open")
      end

      Reviewkit::Current.set(actor: reviewer, source: "spec") do
        review.approve!
      end
    end

    created_event = events.find { |event| event.name == "reviewkit.review.created" }
    status_event = events.find { |event| event.name == "reviewkit.review.status_changed" }

    expect(created_event.payload).to include(actor: reviewer, record: review, source: "spec")
    expect(status_event.payload).to include(actor: reviewer, record: review, from: "open", to: "approved")
  end

  it "publishes status change notifications for review threads" do
    reviewer = create(:reviewer)
    thread = create(:reviewkit_review_thread, status: "open")
    events = capture_reviewkit_events("reviewkit.review_thread.status_changed") do
      Reviewkit::Current.set(actor: reviewer, source: "spec") do
        thread.resolve!
      end
    end

    status_event = events.fetch(0)

    expect(status_event.payload).to include(actor: reviewer, record: thread, from: "open", to: "resolved")
  end

  it "publishes update notifications for comments" do
    reviewer = create(:reviewer)
    comment = create(:reviewkit_comment)
    events = capture_reviewkit_events("reviewkit.comment.updated") do
      Reviewkit::Current.set(actor: reviewer, source: "spec") do
        comment.update!(body: "Updated body")
      end
    end

    update_event = events.fetch(0)

    expect(update_event.payload).to include(actor: reviewer, record: comment, source: "spec")
  end

  def capture_reviewkit_events(*names)
    events = []
    subscribers = names.map do |name|
      ActiveSupport::Notifications.subscribe(name) do |*args|
        events << ActiveSupport::Notifications::Event.new(*args)
      end
    end

    yield
    events
  ensure
    subscribers&.each { |subscriber| ActiveSupport::Notifications.unsubscribe(subscriber) }
  end
end
