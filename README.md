# F(x)

[![Build Status](https://travis-ci.com/thoughtbot/fx.svg)](https://travis-ci.com/thoughtbot/fx)

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

## Great, how do I create a function?

You've got this great idea for a function you'd like to call `assert`. You can
create the migration and the corresponding definition file with the following
command:

```sh
$ rails generate fx:function assert
      create  db/functions/assert_results_v01.sql
      create  db/migrate/[TIMESTAMP]_create_assert.rb
```

Edit the `db/functions/assert_v01.sql` file with the SQL statement that
defines your function. In our example, this might look something like this:

```sql
CREATE OR REPLACE FUNCTION assert(a text, b text) RETURNS boolean
AS $$
BEGIN
    IF (a = b) THEN
        RETURN true;
    ELSE
        RAISE EXCEPTION 'AssertionError';
    END IF;
END;
$$ LANGUAGE plpgsql;

```

The generated migration will contain a `create_function` statement. The
migration is reversible and the schema will be dumped into your `schema.rb`
file.

```sh
$ rake db:migrate
```

## Cool, but what if I need to change the function?

Here's where F(x) really shines. Run that same function generator once more:

```sh
$ rails generate fx:function assert
      create  db/functions/assert_v02.sql
      create  db/migrate/[TIMESTAMP]_update_assert_to_version_2.rb
```

F(x) detected that we already had an existing `assert` function at version 1,
created a copy of that definition as version 2, and created a migration to
update to the version 2 schema. All that's left for you to do is tweak the
schema in the new definition and run the `update_function` migration.

## I don't need this function anymore. Make it go away.

Scenic gives you `drop_function` too:

```ruby
def change
  drop_function :assert, revert_to_version: 2
end
```

## About

Fx(x) is maintained by thoughtbot, inc. The names and logos for thoughtbot are
trademarks of thoughtbot, inc.

We love open source software!  See [our other projects][community] or [hire
us][hire] to help build your product.

[community]: https://thoughtbot.com/community?utm_source=github
[hire]: https://thoughtbot.com/hire-us?utm_source=github
