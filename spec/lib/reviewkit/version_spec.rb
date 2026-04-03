# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reviewkit::VERSION" do
  it "uses a semantic version string" do
    expect(Reviewkit::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
