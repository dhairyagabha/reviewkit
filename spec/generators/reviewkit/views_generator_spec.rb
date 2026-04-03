# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require "generators/reviewkit/views/views_generator"

RSpec.describe Reviewkit::Generators::ViewsGenerator do
  around do |example|
    Dir.mktmpdir("reviewkit-views-generator") do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "app", "views"))
      example.run
    end
  end

  it "copies the shipped engine views into the host app" do
    generator = described_class.new([], {}, destination_root: @destination_root)

    generator.copy_views

    expect(File).to exist(File.join(@destination_root, "app", "views", "reviewkit", "reviews", "show.html.erb"))
    expect(File).to exist(File.join(@destination_root, "app", "views", "reviewkit", "review_threads", "_thread.html.erb"))
    expect(File).to exist(File.join(@destination_root, "app", "views", "reviewkit", "review_threads", "_bucket_row.html.erb"))
    expect(File).to exist(File.join(@destination_root, "app", "views", "reviewkit", "review_threads", "_edit_form.html.erb"))
  end
end
