# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require "generators/changeset/controllers/controllers_generator"

RSpec.describe Changeset::Generators::ControllersGenerator do
  around do |example|
    Dir.mktmpdir("changeset-controllers-generator") do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "app", "controllers", "concerns"))
      example.run
    end
  end

  it "copies controller extension concerns into the host app" do
    generator = described_class.new([], {}, destination_root: @destination_root)

    generator.copy_controller_extensions

    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "changeset", "reviews_controller_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "changeset", "review_threads_controller_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "changeset", "comments_controller_extension.rb"))
    expect(File.read(File.join(@destination_root, "app", "controllers", "concerns", "changeset", "reviews_controller_extension.rb"))).to include("permitted_review_attributes")
  end
end
