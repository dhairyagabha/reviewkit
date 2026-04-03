source "https://rubygems.org"

gemspec

gem "puma"
gem "propshaft"
gem "sqlite3", ">= 2.2"

group :development, :test do
  gem "capybara"
  gem "factory_bot_rails"
  gem "rbs", require: false
  gem "rspec-rails", "~> 8.0"
  gem "simplecov", require: false
  gem "rubocop", "~> 1.81", require: false
  gem "rubocop-factory_bot", "~> 2.26", require: false
  gem "rubocop-rspec", "~> 3.6", require: false
  gem "rubocop-rails-omakase", "~> 1.1", require: false
  gem "webmock"
end

group :development do
  gem "brakeman", require: false
  gem "tailwindcss-rails", require: false
end
