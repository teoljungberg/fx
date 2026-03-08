require "acceptance_helper"

RSpec.describe "Function sorting" do
  it "sorts functions by definition when configured" do
    write_initializer <<~RUBY
      Fx.configure do |config|
        config.function_sorter = Fx::FunctionsSortByDefinition
      end
    RUBY

    successfully "rails generate fx:function value"
    write_function_definition "value_v01", <<~SQL
      CREATE OR REPLACE FUNCTION value(x integer)
      RETURNS integer AS $$
      BEGIN
          RETURN x;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    successfully "rails generate fx:function make_incr"
    write_function_definition "make_incr_v01", <<~SQL
      CREATE OR REPLACE FUNCTION make_incr(x integer)
      RETURNS integer AS $$
      BEGIN
          RETURN value(x) + 1;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    successfully "rake db:migrate"

    schema = File.read("db/schema.rb")
    value_pos = schema.index("create_function :value")
    make_incr_pos = schema.index("create_function :make_incr")

    expect(value_pos).to be < make_incr_pos
  end

  it "sorts functions by catalog when configured" do
    write_initializer <<~RUBY
      Fx.configure do |config|
        config.function_sorter = Fx::FunctionsSortByCatalog
      end
    RUBY

    successfully "rails generate fx:function add"
    write_function_definition "add_v01", <<~SQL
      CREATE OR REPLACE FUNCTION add(a integer, b integer)
      RETURNS integer
      LANGUAGE SQL
      BEGIN ATOMIC
        SELECT a + b;
      END;
    SQL

    successfully "rails generate fx:function add_three"
    write_function_definition "add_three_v01", <<~SQL
      CREATE OR REPLACE FUNCTION add_three(a integer, b integer, c integer)
      RETURNS integer
      LANGUAGE SQL
      BEGIN ATOMIC
        SELECT add(add(a, b), c);
      END;
    SQL

    successfully "rake db:migrate"

    schema = File.read("db/schema.rb")
    add_pos = schema.index("create_function :add")
    add_three_pos = schema.index("create_function :add_three")

    expect(add_pos).to be < add_three_pos
  end

  private

  def write_initializer(content)
    FileUtils.mkdir_p("config/initializers")
    File.write("config/initializers/fx.rb", content)
  end
end
