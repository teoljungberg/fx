# F(x)

[![Build Status](https://github.com/teoljungberg/fx/actions/workflows/ci.yml/badge.svg)](https://github.com/teoljungberg/fx/actions/workflows/ci.yml)

F(x) adds methods to `ActiveRecord::Migration` to create and manage database
functions and triggers in Rails.

Using F(x), you can bring the power of SQL functions and triggers to your Rails
application without having to switch your schema format to SQL. F(x) provides
a convention for versioning functions and triggers that keeps your migration
history consistent and reversible and avoids having to duplicate SQL strings
across migrations. As an added bonus, you define the structure of your function
in a SQL file, meaning you get full SQL syntax highlighting in the editor of
your choice and can easily test your SQL in the database console during
development.

F(x) ships with support for PostgreSQL. The adapter is configurable (see
`Fx::Configuration`) and has a minimal interface (see
`Fx::Adapters::Postgres`) that other gems can provide.

## Great, how do I create a trigger and a function?

You've got this great idea for a function you'd like to call
`uppercase_users_name`. You can create the migration and the corresponding
definition file with the following command:

```sh
% rails generate fx:function uppercase_users_name
      create  db/functions/uppercase_users_name_v01.sql
      create  db/migrate/[TIMESTAMP]_create_function_uppercase_users_name.rb
```

Edit the `db/functions/uppercase_users_name_v01.sql` file with the SQL statement
that defines your function.

Next, let's add a trigger called `uppercase_users_name` to call our new
function each time we `INSERT` on the `users` table.

```sh
% rails generate fx:trigger uppercase_users_name table_name:users
      create  db/triggers/uppercase_users_name_v01.sql
      create  db/migrate/[TIMESTAMP]_create_trigger_uppercase_users_name.rb
```

In our example, this might look something like this:

```sql
CREATE TRIGGER uppercase_users_name
    BEFORE INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION uppercase_users_name();
```

The generated migrations contains `create_function` and `create_trigger`
statements. The migration is reversible and the schema will be dumped into your
`schema.rb` file.

```sh
% rake db:migrate
```

## Cool, but what if I need to change a trigger or function?

Here's where F(x) really shines. Run that same function generator once more:

```sh
% rails generate fx:function uppercase_users_name
      create  db/functions/uppercase_users_name_v02.sql
      create  db/migrate/[TIMESTAMP]_update_function_uppercase_users_name_to_version_2.rb
```

F(x) detected that we already had an existing `uppercase_users_name` function at
version 1, created a copy of that definition as version 2, and created a
migration to update to the version 2 schema. All that's left for you to do is
tweak the schema in the new definition and run the `update_function` migration.

## I don't need this trigger or function anymore. Make it go away.

F(x) gives you `drop_trigger` and `drop_function` too:

```ruby
def change
  drop_function :uppercase_users_name, revert_to_version: 2
end
```

## What if I need to use a function as the default value of a column?

You need to set F(x) to dump the functions in the beginning of db/schema.rb in a
initializer:

```ruby
# config/initializers/fx.rb
Fx.configure do |config|
  config.dump_functions_at_beginning_of_schema = true
end
```

And then you can use a lambda in your migration file:

```ruby
create_table :my_table do |t|
  t.string :my_column, default: -> { "my_function()" }
end
```

That's how you tell Rails to use the default as a literal SQL for the default
column value instead of a plain string.

## Customizing Schema Dump Order

By default, functions and triggers are dumped to `schema.rb` in the order
returned by the database. If you need a specific ordering (e.g., alphabetical
for deterministic diffs), subclass the adapter and override `#functions` or
`#triggers`. These methods are part of the adapter's public API and will remain
stable across releases:

```ruby
# config/initializers/fx.rb
class SortedPostgresAdapter < Fx::Adapters::Postgres
  def functions
    super.sort_by(&:name)
  end

  def triggers
    super.sort_by(&:name)
  end
end

Fx.configure do |config|
  config.database = SortedPostgresAdapter.new
end
```

The same approach works for more advanced ordering. For example, if your
functions depend on each other and need to be dumped in dependency order, you
could use Ruby's built-in `TSort` to topologically sort them.

## Fast, isolated test databases

Functions and triggers are most interesting to test against a *real* database:
a `BEFORE INSERT` trigger only fires when you actually write a row, and a
function's behavior depends on committed data. Wrapping every test in a
transaction and rolling back gets in the way of that.

`Fx::TestDatabase` builds a PostgreSQL *template* database once — loading the
full schema, including your F(x) functions and triggers — and then clones a
fresh, throwaway database from it for each test using
`CREATE DATABASE ... TEMPLATE ...`, which PostgreSQL performs as a fast
file-level copy. Every test gets its own real database, so triggers fire and
functions run exactly as they do in production. This follows the template
database pattern described in [pgtestdb].

[pgtestdb]: https://brandur.org/fragments/pgtestdb

It is not required to use F(x) and is not loaded by default:

```ruby
require "fx/test_database"

test_database = Fx::TestDatabase.new(
  ActiveRecord::Base.connection_db_config.configuration_hash,
  template: "myapp_test_template"
)
```

Build the template once (for example, in a `before(:suite)` hook). Load your
schema however you already do — `db/schema.rb`, `structure.sql`, or by running
migrations — against the connection F(x) hands to the block:

```ruby
test_database.create_template do |connection|
  load(Rails.root.join("db/schema.rb"))
end
```

Then, in each test, clone a database, run against it, and drop it afterwards:

```ruby
test_database.with_instance do |connection|
  users(:alice)               # fixtures are available
  User.create!(name: "bob")   # a real write — triggers fire
  User.find_by(name: "bob").upper_name # => "BOB"
end
```

While the block runs, the connection class (`ActiveRecord::Base` by default) is
pointed at the clone, so your models and fixtures operate against it. The
original connection is restored when the block returns.

A note on fixtures: Rails loads fixtures with referential integrity disabled
(`session_replication_role = replica`), which also suppresses ordinary
triggers. Fixture rows are therefore inserted verbatim, exactly as in a normal
Rails test — it is the real writes your test performs that exercise your
functions and triggers.

Cloning a database costs roughly 100ms. For a large suite that adds up, so
`with_instance` can instead reuse databases from a pool. When the block
succeeds, the database is truncated (schema, functions, and triggers are left
intact) and returned to the pool for the next test, which is far faster than
cloning afresh:

```ruby
test_database.with_instance(reuse: true) do |connection|
  # ...
end

# Once, after the whole suite:
test_database.shutdown
```

If the block raises while reusing, that database is left in place — out of the
pool — so you can inspect the failed state; `shutdown` drops it along with the
rest. The pool is per-process and not thread-safe, which suits Ruby's
process-based parallel test runners.

## Plugins/Adapters

- [MySQL](https://github.com/f-mer/fx-adapters-mysql/)
- [Oracle](https://github.com/zygotecnologia/fx-oracle-adapter)
- [SQLserver](https://github.com/tarellel/fx-sqlserver-adapter)

## Version Support

F(x) follows the maintenance policies of Ruby, Rails, and PostgreSQL, supporting
versions within their official maintenance windows.

**Ruby:** 3.3+ ([maintenance branches])

**Rails:** 7.2, 8.0, 8.1 ([maintenance policy])

**PostgreSQL:** 14, 15, 16, 17, 18 ([versioning policy])

When a version reaches end-of-life, support will be dropped in the next minor
release of F(x). Older versions may continue to work but are not tested or
guaranteed.

[maintenance branches]: https://www.ruby-lang.org/en/downloads/branches/
[maintenance policy]: https://rubyonrails.org/maintenance
[versioning policy]: https://www.postgresql.org/support/versioning/

## Contributing

See [contributing](CONTRIBUTING.md) for more details.
