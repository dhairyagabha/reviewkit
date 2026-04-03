# frozen_string_literal: true

require "rails_helper"
require "tmpdir"
require "generators/changeset/install/install_generator"

RSpec.describe Changeset::Generators::InstallGenerator do
  around do |example|
    Dir.mktmpdir("changeset-install-generator") do |directory|
      @destination_root = directory
      FileUtils.mkdir_p(File.join(directory, "config", "initializers"))
      File.write(File.join(directory, "config", "routes.rb"), "Rails.application.routes.draw do\nend\n")
      example.run
    end
  end

  it "copies the initializer, mounts the engine, and prints the next steps" do
    generator = described_class.new([], { mount: true, mount_path: "/reviews" }, destination_root: @destination_root)

    allow(generator).to receive(:rake)
    allow(generator).to receive(:say)

    generator.copy_initializer
    generator.ensure_importmap
    generator.mount_engine
    generator.install_migrations
    generator.print_instructions

    expect(File.read(File.join(@destination_root, "config", "initializers", "changeset.rb"))).to include("Changeset.configure")
    expect(File.read(File.join(@destination_root, "config", "initializers", "changeset.rb"))).to include("config.intraline_limits.max_review_files = 50")
    expect(File.read(File.join(@destination_root, "config", "initializers", "changeset.rb"))).to include("config.intraline_limits.max_changed_lines = 50")
    expect(File.read(File.join(@destination_root, "config", "importmap.rb"))).to include("Changeset relies on importmap-rails")
    expect(File.read(File.join(@destination_root, "config", "routes.rb"))).to include('mount Changeset::Engine => "/reviews"')
    expect(generator).to have_received(:rake).with("changeset:install:migrations")
    expect(generator).to have_received(:say).with("Changeset installed.", :green)
    expect(generator).to have_received(:say).with("  2. Visit /reviews once you create review data")
    expect(generator).to have_received(:say).with("  5. Optionally run rails g changeset:models for host-side validations, scopes, and callbacks")
    expect(generator).to have_received(:say).with("  6. Optionally run rails g changeset:controllers to extend permitted params and controller flow")
  end

  it "skips route insertion when mounting is disabled" do
    generator = described_class.new([], { mount: false }, destination_root: @destination_root)
    allow(generator).to receive(:rake)
    allow(generator).to receive(:say)

    generator.mount_engine

    expect(File.read(File.join(@destination_root, "config", "routes.rb"))).not_to include("mount Changeset::Engine")
  end

  it "does not overwrite an existing host importmap" do
    File.write(File.join(@destination_root, "config", "importmap.rb"), %(pin "application"))
    generator = described_class.new([], {}, destination_root: @destination_root)

    generator.ensure_importmap

    expect(File.read(File.join(@destination_root, "config", "importmap.rb"))).to eq(%(pin "application"))
  end
end
