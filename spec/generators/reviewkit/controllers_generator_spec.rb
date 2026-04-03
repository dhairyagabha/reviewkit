# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require "generators/reviewkit/controllers/controllers_generator"

RSpec.describe Reviewkit::Generators::ControllersGenerator do
  around do |example|
    Dir.mktmpdir("reviewkit-controllers-generator") do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "app", "controllers", "concerns"))
      example.run
    end
  end

  it "copies controller extension concerns into the host app" do
    generator = described_class.new([], {}, destination_root: @destination_root)

    generator.copy_controller_extensions

    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "reviewkit", "reviews_controller_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "reviewkit", "review_threads_controller_extension.rb"))
    expect(File).to exist(File.join(@destination_root, "app", "controllers", "concerns", "reviewkit", "comments_controller_extension.rb"))
    expect(File.read(File.join(@destination_root, "app", "controllers", "concerns", "reviewkit", "reviews_controller_extension.rb"))).to include("permitted_review_attributes")
  end
end
