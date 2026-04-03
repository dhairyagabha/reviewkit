require_relative "lib/changeset/version"

Gem::Specification.new do |spec|
  spec.name                  = "changeset"
  spec.version               = Changeset::VERSION
  spec.authors               = [ "Dhairya Gabhawala" ]
  spec.email                 = [ "gabhawaladhairya@gmail.com" ]
  spec.summary               = "Git-style code review Rails engine with diff rendering and threaded line comments."
  spec.description           = "Changeset is a mountable Rails engine for rendering Git-like code diffs, " \
                               "persisting threaded line comments, and embedding review workflows into host apps."
  spec.homepage              = "https://changeset.dhairyagabhawala.com"
  spec.license               = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/dhairyagabha/changeset"
  spec.metadata["bug_tracker_uri"] = "https://github.com/dhairyagabha/changeset/issues"
  spec.metadata["changelog_uri"] = "https://github.com/dhairyagabha/changeset/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://changeset.dhairyagabhawala.com/docs/installation"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir[
      "{app,bin,config,db,lib,sig}/**/*",
      "app/assets/builds/**/*",
      "CHANGELOG.md",
      "CODE_OF_CONDUCT.md",
      "CONTRIBUTING.md",
      "MIT-LICENSE",
      "README.md",
      "Rakefile",
      "SECURITY.md"
    ]
  end

  spec.add_dependency "diff-lcs", "~> 1.6"
  spec.add_dependency "importmap-rails", ">= 2.0", "< 3.0"
  spec.add_dependency "rails", ">= 8.1.2", "< 8.2"
  spec.add_dependency "rouge", "~> 4.5"
  spec.add_dependency "stimulus-rails", ">= 1.3", "< 2.0"
  spec.add_dependency "turbo-rails", ">= 2.0", "< 3.0"
end
