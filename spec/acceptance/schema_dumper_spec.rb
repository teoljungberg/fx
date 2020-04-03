require "acceptance_helper"

describe "Schema dumper" do
  it "dumps and loads functions in the correct order" do
    if Rails::VERSION::MAJOR < 5
      skip "Rails < 5 does not support functions as default values in schema.rb"
    end

    execute <<-EOS
      CREATE OR REPLACE FUNCTION products_version()
      RETURNS text AS $$
      BEGIN
          RETURN 'v1';
      END;
      $$ LANGUAGE plpgsql;
    EOS

    execute <<-EOS
      CREATE TABLE products (
        name varchar(255),
        version varchar(255) DEFAULT products_version()
      )
    EOS

    execute <<-EOS
      INSERT INTO products
      (name)
      VALUES
      ('fx')
    EOS

    result = execute("SELECT version FROM products WHERE name = 'fx'")
    expect(result).to eq("version" => "v1")

    successfully "rake db:schema:dump"

    # Is not possible to use `rake db:drop` because the connection is being
    # used. Dropping both entities will do the job.
    execute <<-EOS
      DROP TABLE products;
      DROP FUNCTION products_version();
    EOS

    successfully "rake db:schema:load"

    execute <<-EOS
      INSERT INTO products
      (name)
      VALUES
      ('fx')
    EOS
    result = execute("SELECT version FROM products WHERE name = 'fx'")
    expect(result).to eq("version" => "v1")
  end
end
