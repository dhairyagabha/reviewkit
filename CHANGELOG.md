# Changelog

All notable changes to this project will be documented in this file.

## [0.1.0] - 2026-03-31

- Initial release of the `reviewkit` mountable Rails engine
- Added split diff rendering with syntax highlighting
- Added threaded line comments with resolve / reopen flows
- Added TailwindCSS and Turbo-powered shipped UI
- Added install and view-copy generators
- Added model and controller extension generators for host apps
- Added Launch-friendly metadata support on reviews, documents, threads, and comments
- Added RSpec, SimpleCov, RuboCop, and CI coverage
- Added a Rails-only asset workflow with no Node or npm requirement
- Reworked actor persistence to use Rails-native polymorphic associations instead of `*_gid` columns
- Replaced the custom hook DSL with standard Rails callbacks, `Reviewkit::Current`, and `ActiveSupport::Notifications`
- Added protected controller extension points for params, scopes, redirects, and flow behavior
- Added a RubyGems Trusted Publishing workflow and trimmed the released gem payload to engine runtime files only
- Added a public documentation site at `https://reviewkit.dhairyagabhawala.com`
- Added a contributor code of conduct and public release metadata cleanup
- Consolidated the RSpec engine dummy app under `spec/dummy` and removed generated placeholder mailer/job classes
- Narrowed the declared Rails dependency to the CI-verified `8.1` line
