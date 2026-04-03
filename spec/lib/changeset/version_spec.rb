# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Changeset::VERSION" do
  it "uses a semantic version string" do
    expect(Changeset::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
