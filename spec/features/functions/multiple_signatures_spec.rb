describe "Functions with multiple signatures", :db do
  around do |example|
    sql_definition = <<-EOS
      CREATE OR REPLACE FUNCTION test()
      RETURNS text AS $$
      BEGIN
          RETURN 'test';
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION test(str text)
      RETURNS text AS $$
      BEGIN
          RETURN str;
      END;
      $$ LANGUAGE plpgsql;
    EOS

    with_function_definition(name: :test, sql_definition: sql_definition) do
      example.run
    end
  end

  it "can create functions with multiple signatures" do
    connection.create_function(:test)

    functions = Fx.database.functions
    expect(functions[0].name).to eq("test")
    expect(functions[0].arguments).to eq("")

    expect(functions[1].name).to eq("test")
    expect(functions[1].arguments).to eq("str text")
  end

  it "drops all functions of the same name but different signatures" do
    connection.create_function(:test)
    connection.drop_function(:test)

    expect(Fx.database.functions).to be_empty
  end
end
