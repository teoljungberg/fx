# Extensible Architecture Review

This document tracks gaps found and changes made while ensuring F(x) follows the plain-object adapter configuration philosophy from `README.md:145`:

> F(x) does not use a plugin-registration system. Instead, adapters are plain Ruby objects that you configure through `Fx.configuration.database`.

## Gaps

### 1. Adapter configuration examples contradicted the plain-object API

- **Where:** `lib/fx/adapters/postgres.rb` YARD examples and `lib/fx.rb` inline example.
- **Issue:** Examples used `config.adapter` or assigned the `Fx::Adapters::Postgres` class instead of `config.database = Fx::Adapters::Postgres.new`.
- **Status:** Fixed. The examples now show a plain object instance assigned to `config.database`.

### 2. Adapter interface contract was not verified in tests

- **Where:** `spec/fx/adapters/postgres_spec.rb`.
- **Issue:** `Postgres` inherits from `AbstractAdapter`, but there was no shared contract verifying that all required methods are implemented with the documented signatures. A new adapter author could miss a method or mismatch an argument name.
- **Status:** Fixed by adding shared examples in `spec/support/shared_examples/adapter_contract.rb` and including them in `postgres_spec.rb`.

### 3. No custom adapter end-to-end test

- **Where:** test suite.
- **Issue:** All tests exercised the Postgres adapter. There was no proof that a plain Ruby object implementing `AbstractAdapter` works with `Fx::Statements` and `Fx::SchemaDumper`.
- **Status:** Fixed by adding `spec/fx/adapters/custom_adapter_integration_spec.rb` with `Fx::TestAdapter` in `spec/support/test_adapter.rb`.

### 4. `AbstractAdapter` was not marked as abstract in YARD

- **Where:** `lib/fx/adapters/abstract_adapter.rb`.
- **Issue:** The class is intended to be subclassed but did not carry an `@abstract` tag.
- **Status:** Fixed.

### 5. Postgres adapter is loaded even when a custom adapter is configured

- **Where:** `lib/fx.rb`.
- **Issue:** The default is Postgres, so `lib/fx.rb` requires `fx/adapters/postgres` at load time. A third-party adapter still works because `Fx.configuration.database` can be reassigned, but the Postgres code is loaded unnecessarily.
- **Status:** Accepted. Changing this would require lazy default initialization and would complicate the boot path for a small gain. The README documents that F(x) ships with Postgres support.

### 6. Domain models expect specific row keys

- **Where:** `lib/fx/function.rb` and `lib/fx/trigger.rb`.
- **Issue:** `Fx::Function` and `Fx::Trigger` expect hashes with `name`, `definition`, and (for functions) `arguments`. A custom adapter can return subclass instances or build its own objects, so this is not a hard blocker.
- **Status:** Documented. `Fx::Adapters::QueryExecutor` already maps rows to a configurable `model_class`. The custom adapter integration test uses `Fx::Function` and `Fx::Trigger` directly from the adapter.

### 7. Domain objects were marked as `@api private` despite being part of the adapter contract

- **Where:** `lib/fx/function.rb` and `lib/fx/trigger.rb`.
- **Issue:** `README.md` tells adapter authors to return `Array<Fx::Function>` and `Array<Fx::Trigger>`, yet the classes were tagged `@api private`.
- **Status:** Fixed. Removed the `@api private` tags and documented their role as the return values for adapter `functions` and `triggers` methods.

### 8. Configuration documentation described the database as Postgres-only

- **Where:** `lib/fx/configuration.rb` and `lib/fx.rb`.
- **Issue:** The YARD and inline documentation said the configured database was a `Fx::Adapters::Postgres` instance, which is misleading for custom adapters.
- **Status:** Fixed. The documentation now describes the configured database as any object implementing `Fx::Adapters::AbstractAdapter` and mentions `Fx::Adapters::Postgres` only as the default.

### 9. `README.md` does not mention `Fx::Adapters::QueryExecutor` as a reusable helper

- **Where:** `README.md`.
- **Issue:** `Fx::Adapters::QueryExecutor` was extracted from the Postgres namespace so other adapters can reuse it, but the README does not point it out.
- **Status:** Accepted. The helper is not required for all adapters, and the YARD documentation in `lib/fx/adapters/query_executor.rb` is sufficient for adapter authors who need it.

## Summary

The adapter layer now has a documented interface (`Fx::Adapters::AbstractAdapter`), a verified contract, an end-to-end integration test, and consistent documentation that treats adapters as plain Ruby objects configured through `Fx.configuration.database`. The remaining accepted limitations are either small performance concerns (loading the Postgres adapter by default) or documentation choices that do not block adapter authors.
