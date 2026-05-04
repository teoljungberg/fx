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

### Topological sort for dependent functions

If your functions reference each other, dump-order matters: a function written
in `LANGUAGE sql` is name-resolved at `CREATE` time, so a referenced function
must already exist when its caller is created. The default order returned by
the database is not guaranteed to be dependency-safe — for example, after
out-of-order migrations across branches, or after dropping and recreating a
function, the on-disk creation order may have flipped.

`pg_depend` looks like the natural source of truth here, but PostgreSQL only
records function-to-function dependencies for new-style (PG14+) SQL functions
written with `RETURN ...` or `BEGIN ATOMIC ... END;`, whose body is stored as
a parsed query tree. The `CREATE OR REPLACE FUNCTION ... LANGUAGE sql AS $$
... $$` form that F(x) generates (and `LANGUAGE plpgsql` functions in general)
store the body as opaque text in `pg_proc.prosrc`, with no `pg_depend` rows
for inter-function references.

A more portable approach is to scan `prosrc` textually for whole-word matches
of other managed function names, then run the resulting graph through Ruby's
`TSort`:

```ruby
# config/initializers/fx.rb
require "tsort"

class TopologicallySortedAdapter < Fx::Adapters::Postgres
  def functions
    fns = super
    sort_by_dependencies(fns)
  end

  private

  def sort_by_dependencies(fns)
    by_name = fns.index_by(&:name)
    deps = fetch_dependencies

    sorter = Class.new do
      include TSort
      def initialize(nodes, deps, by_name)
        @nodes, @deps, @by_name = nodes, deps, by_name
      end
      def tsort_each_node(&blk) = @nodes.each(&blk)
      def tsort_each_child(node, &blk)
        Array(@deps[node.name])
          .map { |n| @by_name[n] }
          .compact
          .each(&blk)
      end
    end

    sorter.new(fns, deps, by_name).tsort
  end

  def fetch_dependencies
    rows = ActiveRecord::Base.connection.exec_query(<<~'SQL', "fx deps")
      SELECT caller.proname AS caller, callee.proname AS callee
      FROM pg_proc caller
      JOIN pg_namespace cns ON cns.oid = caller.pronamespace
      LEFT JOIN pg_depend cd ON cd.objid = caller.oid AND cd.deptype = 'e'
      LEFT JOIN pg_aggregate ca ON ca.aggfnoid = caller.oid
      JOIN pg_proc callee ON callee.oid <> caller.oid
      JOIN pg_namespace ens ON ens.oid = callee.pronamespace
      LEFT JOIN pg_depend ed ON ed.objid = callee.oid AND ed.deptype = 'e'
      LEFT JOIN pg_aggregate ea ON ea.aggfnoid = callee.oid
      WHERE cns.nspname = ANY (current_schemas(false))
        AND ens.nspname = ANY (current_schemas(false))
        AND cd.objid IS NULL AND ca.aggfnoid IS NULL
        AND ed.objid IS NULL AND ea.aggfnoid IS NULL
        AND caller.prosrc ~ ('\m' || callee.proname || '\M');
    SQL

    rows.each_with_object(Hash.new { |h, k| h[k] = [] }) do |r, acc|
      acc[r["caller"]] << r["callee"]
    end
  end
end

Fx.configure do |config|
  config.database = TopologicallySortedAdapter.new
end
```

A few notes on the query and the technique:

- The heredoc is `<<~'SQL'` (single-quoted marker) so Ruby leaves `\m` and
  `\M` alone — those are PostgreSQL regex word-boundary anchors that match a
  callee name as a whole word in the caller's body source.
- Both sides of the join apply the same filters F(x) uses for its own dump
  query: `pg_namespace` restricted to the current search path,
  `pg_depend.deptype = 'e'` excluded so extension-owned functions don't
  appear, and `pg_aggregate.aggfnoid IS NULL` so aggregates don't either.
  The result is a graph over the same set of functions F(x) is about to dump.
- Built-in or extension function names that happen to appear in a body
  (`sum`, `round`, `unnest`, …) will produce edges in the raw query result,
  but they're harmless — the graph drops them when `@by_name` lookup returns
  no matching node.
- `TSort#tsort` raises `TSort::Cyclic` on a true cycle. PostgreSQL would
  reject the cycle at `CREATE` time anyway, so the loud failure is fine.

Unlike a `pg_depend`-based approach, this technique works uniformly for
`LANGUAGE sql`, `LANGUAGE plpgsql`, and any other language whose body is
stored in `pg_proc.prosrc`.

## Plugins/Adapters

- [MySQL](https://github.com/f-mer/fx-adapters-mysql/)
- [Oracle](https://github.com/zygotecnologia/fx-oracle-adapter)
- [SQLserver](https://github.com/tarellel/fx-sqlserver-adapter)

## Version Support

F(x) follows the maintenance policies of Ruby, Rails, and PostgreSQL, supporting
versions within their official maintenance windows.

**Ruby:** 3.2+ ([maintenance branches])

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
