# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require File.expand_path("dummy/config/environment", __dir__)
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "factory_bot_rails"

engine_migrations = Changeset::Engine.paths["db/migrate"].existent.map(&:to_s)
dummy_migrations = [ File.expand_path("dummy/db/migrate", __dir__) ]
all_migration_paths = engine_migrations + dummy_migrations
ActiveRecord::Migrator.migrations_paths = all_migration_paths
ActiveRecord::Tasks::DatabaseTasks.migrations_paths = all_migration_paths

migration_context = ActiveRecord::MigrationContext.new(
  all_migration_paths,
  ActiveRecord::Base.connection_pool.schema_migration,
  ActiveRecord::Base.connection_pool.internal_metadata
)
schema_migration = ActiveRecord::Base.connection_pool.schema_migration
missing_versions = migration_context.migrations.map { |migration| migration.version.to_s } - schema_migration.normalized_versions

if missing_versions.any?
  required_tables = %w[
    changeset_comments
    changeset_documents
    changeset_review_threads
    changeset_reviews
    reviewers
  ]

  unless (required_tables - ActiveRecord::Base.connection.tables).empty?
    abort("The dummy app database is not prepared. Run `bundle exec bin/rails app:db:prepare` before running specs.")
  end

  missing_versions.each { |version| schema_migration.create_version(version) }
end

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError
  pending_versions = migration_context.migrations.map { |migration| migration.version.to_s } - schema_migration.normalized_versions
  pending_versions.each { |version| schema_migration.create_version(version) }
  ActiveRecord::Migration.maintain_test_schema!
end

Dir[Changeset::Engine.root.join("spec/support/**/*.rb")].sort.each { |file| require file }
FactoryBot.definition_file_paths = [ Changeset::Engine.root.join("spec/factories").to_s ]
FactoryBot.find_definitions

RSpec.configure do |config|
  config.fixture_paths = [ Changeset::Engine.root.join("spec/fixtures").to_s ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  config.before do
    Changeset.reset_configuration!
    Changeset::Current.reset
    Changeset::Review.reset_host_status_transitions! if Changeset::Review.respond_to?(:reset_host_status_transitions!)
  end

  config.after do
    Changeset.reset_configuration!
    Changeset::Current.reset
    Changeset::Review.reset_host_status_transitions! if Changeset::Review.respond_to?(:reset_host_status_transitions!)
  end
end
