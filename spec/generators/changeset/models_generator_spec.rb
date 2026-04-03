# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require "generators/changeset/models/models_generator"

RSpec.describe Changeset::Generators::ModelsGenerator do
  around do |example|
    Dir.mktmpdir("changeset-models-generator") do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "app", "models", "concerns"))
      example.run
    end
  end

  it "copies model extension concerns into the host app" do
    generator = described_class.new([], {}, destination_root: @destination_root)

    generator.copy_model_extensions

    expect(File).to exist(File.join(@destination_root, "app", "models", "concerns", "changeset", "review_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "models", "concerns", "changeset", "review_thread_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "models", "concerns", "changeset", "comment_extension.rb"))
    expect(File.read(File.join(@destination_root, "app", "models", "concerns", "changeset", "review_extension.rb"))).to include("saved_change_to_status?")
  end
end
