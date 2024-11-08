# Changelog

The noteworthy changes for each version are included here. For a complete
changelog, see the [commits] for each version via the version links.

[commits]: https://github.com/teoljungberg/fx/commits/master

## [Unreleased]

[Unreleased]: https://github.com/teoljungberg/fx/compare/v0.8.0..HEAD

## [0.9.0]

[0.9.0]: https://github.com/teoljungberg/fx/compare/v0.8.0...v0.9.0

- Drop EOL Rails versions (6.2)
- Add Ruby 3.4.0 preview's to the test matrix (#152)
- Add Rails 8.0.0 to the test matrix (#152)
- Add Rails 7.2 to the test matrix (#150)
- Fix deprecation warnings in Rails (#148)
- Mark `Fx::CommandRecorder::Arguments` as private.
- Add Ruby 3.3 to the test matrix (#144)
- Internal refactorings:
  - Move development dependencies to Gemfile (#145)
  - Inline `Fx::CommandRecorder::Arguments`
  - Inline `Fx::{CommandRecorder,SchemaDumper,Statements}::{Function,Trigger}`
  - Move configuration methods to `Fx`
- Add `Fx::Definition.{function,trigger}` (#119)
- Add Rails 7.1 to the test matrix (#136)
- Add Rubygems metadata to gemspec (#132)
- Disable RSpec's monkey patching (#121)
- Raise on warnings (#124)
- Require Ruby >= 3.0 (#128)
- Require Rails >= 6.1 (#127)

## [0.8.0]

[0.8.0]: https://github.com/teoljungberg/fx/compare/v0.7.0...v0.8.0

- Replace Travis CI with GitHub Actions.
- Bump minimum Ruby version to 2.7.
   - Ruby 2.7 will be dropped in end of March 2023, so a release to drop it will
     happen afterwards.
- Bump minimum Rails version to 6.0.0
   - Rails 6.0 will be dropped in June 2023, so a release to drop it will happen
     afterwards
- Adopt standard.rb
- Contributing improvements
- Test-suite improvements

## [0.7.0]

[0.7.0]: https://github.com/teoljungberg/fx/compare/v0.6.2...v0.7.0

- Support Ruby 3 (#76)
- Preserve backslashes when dumping the schema (#71)
- Add a link to F(x) SqlServer Adapter in the README (#80)

## [0.6.2]

[0.6.2]: https://github.com/teoljungberg/fx/compare/v0.6.1...v0.6.2

- Add support for Ruby 3

## [0.6.1]

[0.6.1]: https://github.com/teoljungberg/fx/compare/v0.6.0...v0.6.1

- Fix: Support --no-migration generator flag (#62)

## [0.6.0]

[0.6.0]: https://github.com/teoljungberg/fx/compare/v0.5.0...v0.6.0

- Support unique functions with parameters (#27)
- Use db connection provided by Rails (#49)
- Support `--no-migration` generator flag (#60)
- Use current ActiveRecord version in migrations (#59)
- Does not include aggregates when dumping schema (#50)
- Dump functions in the beginning of the schema (#53)

## [0.5.0]

[0.5.0]: https://github.com/teoljungberg/fx/compare/v0.4.0...v0.5.0

- Drop EOL Ruby versions.
- Drop EOL Rails versions.

## [0.4.0]

[0.4.0]: https://github.com/teoljungberg/fx/compare/v0.3.1...v0.4.0

- Add table_name to README (#15)
- Reverse function/trigger order in README (#17)
- Split up Trigger#definition test (#19)
- Find definitions in engines (#18)

## [0.3.1]

[0.3.1]: https://github.com/teoljungberg/fx/compare/v0.3.0...v0.3.1

- Strip shared leading whitespace from sql_definitions (#13)
- Update documentation for `drop_function`
- Document `Fx::Adapters::Postgres#initialize`
- Fix test suite issues:
   - Add unit test coverage for `Fx::Adapters::Triggers`
   - Add unit test coverage for `Fx::Adapters::Functions`
   - Add unit test coverage for `Fx::Trigger`
   - Add unit test coverage for `Fx::Function`

## [0.3.0]

[0.3.0]: https://github.com/teoljungberg/fx/compare/v0.2.0...v0.3.0

## [0.2.0]

[0.2.0]: https://github.com/teoljungberg/fx/compare/v0.1.0...v0.2.0

## [0.1.0]

F(x) adds methods to `ActiveRecord::Migration` to create and manage database
functions and triggers in Rails.

[0.1.0]: https://github.com/teoljungberg/fx/compare/4ccf986643d9de82038977eff8c6b1a4a716d698...v0.1.0
