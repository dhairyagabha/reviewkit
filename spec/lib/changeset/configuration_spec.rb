# frozen_string_literal: true

require "rails_helper"

RSpec.describe Changeset::Configuration do
  around do |example|
    Changeset.reset_configuration!
    example.run
    Changeset.reset_configuration!
  end

  it "ships conservative default intraline limits" do
    limits = described_class.new.intraline_limits

    expect(limits.enabled).to be(true)
    expect(limits.max_review_files).to eq(50)
    expect(limits.max_changed_lines).to eq(50)
    expect(limits.max_line_length).to eq(500)
  end
end
