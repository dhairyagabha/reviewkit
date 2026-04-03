# frozen_string_literal: true

require "rails_helper"
require "rbs"

RSpec.describe "Changeset RBS signatures" do
  let(:project_root) { File.expand_path("../../..", __dir__) }

  it "parse cleanly" do
    Dir[File.join(project_root, "sig/**/*.rbs")].sort.each do |path|
      source = File.read(path)

      expect { RBS::Parser.parse_signature(source) }.not_to raise_error, "expected #{path} to parse as valid RBS"
    end
  end

  it "includes the signature directory in the gem package manifest" do
    gemspec_source = File.read(File.join(project_root, "changeset.gemspec"))

    expect(gemspec_source).to include("{app,bin,config,db,lib,sig}/**/*")
  end
end
