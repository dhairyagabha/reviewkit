# Contributing

Please review the [Code of Conduct](CODE_OF_CONDUCT.md) before participating.

## Setup

```bash
bin/setup
```

That will:

- install Ruby gems
- build the shipped frontend assets
- prepare the dummy app database

## Development Workflow

- implement changes in the engine under `app/`, `lib/`, and `db/`
- use `spec/dummy` as the host application for manual verification
- keep shipped CSS up to date with `bundle exec rake changeset:build_assets` when frontend styling changes land

## Verification

Before opening a pull request, run:

```bash
bin/test
bin/lint
bundle exec bin/rails app:zeitwerk:check
bundle exec rake changeset:build_assets
```

## Scope Guidelines

- keep `Changeset` generic and host-app friendly
- store domain-specific context, such as Adobe Launch resource identifiers, in metadata instead of adding vendor-specific columns unless the engine truly needs them
- preserve the shipped UI as a polished default, even when adding override points for host applications

## Pull Requests

- include tests for new behavior
- update documentation when public behavior changes
- add a changelog entry for user-visible changes
