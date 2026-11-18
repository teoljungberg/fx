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

## Extending F(x)

F(x) is built around a small adapter interface. The adapter assigned to
`config.database` is the extension point: subclass
`Fx::Adapters::Postgres` to customize behavior, or write an adapter of your
own. An adapter responds to `functions` and `triggers`, returning the
`Fx::Function` and `Fx::Trigger` instances to dump into `schema.rb`, and to
the methods the migration statements call: `create_function(sql_definition)`,
`drop_function(name)`, `update_function(name, sql_definition)`,
`create_trigger(sql_definition)`, `drop_trigger(name, on:)`, and
`update_trigger(name, on:, sql_definition:)`.

`Fx::Function` and `Fx::Trigger` are constructed from a hash with `"name"`
and `"definition"` keys; functions optionally take `"arguments"`, the
identity arguments used to disambiguate overloaded functions. These methods
and classes are the public API of F(x) and remain stable across releases.

### Customizing the schema dump

By default, functions and triggers are dumped to `schema.rb` in the order
returned by the database. If you need a specific ordering (e.g., alphabetical
for deterministic diffs), override `#functions` or `#triggers`:

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

Filtering works the same way. If F(x) dumps something you do not want, such
as a trigger owned by an extension, reject it:

```ruby
class PostgisAdapter < Fx::Adapters::Postgres
  def triggers
    super.reject { |trigger| trigger.name == "layer_integrity_checks" }
  end
end
```

And if F(x) skips something you want dumped, add it yourself:

```ruby
class MyAdapter < Fx::Adapters::Postgres
  def triggers
    super + [Fx::Trigger.new(
      "name" => "audit_log",
      "definition" => "CREATE TRIGGER audit_log ..."
    )]
  end
end
```

### Adding migration statements

To manage other database objects, define the method on your adapter subclass
and expose it to migrations the way F(x) exposes its own statements:

```ruby
class OperatorAdapter < Fx::Adapters::Postgres
  def create_operator(sql_definition)
    connection.execute(sql_definition)
  end
end

module OperatorStatements
  def create_operator(sql_definition)
    Fx.database.create_operator(sql_definition)
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.include(OperatorStatements)
```

## Plugins/Adapters

- [MySQL](https://github.com/f-mer/fx-adapters-mysql/)
- [Oracle](https://github.com/zygotecnologia/fx-oracle-adapter)
- [SQLserver](https://github.com/tarellel/fx-sqlserver-adapter)

## Version Support

F(x) follows the maintenance policies of Ruby, Rails, and PostgreSQL, supporting
versions within their official maintenance windows.

**Ruby:** 3.3+ ([maintenance branches])

**Rails:** 8.1 ([maintenance policy])

**PostgreSQL:** 15, 16, 17, 18 ([versioning policy])

When a version reaches end-of-life, support will be dropped in the next minor
release of F(x). Older versions may continue to work but are not tested or
guaranteed.

[maintenance branches]: https://www.ruby-lang.org/en/downloads/branches/
[maintenance policy]: https://rubyonrails.org/maintenance
[versioning policy]: https://www.postgresql.org/support/versioning/

## Contributing

See [contributing](CONTRIBUTING.md) for more details.
