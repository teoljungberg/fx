describe "Functions with multiple definitions", :db do
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

  let(:functions) { Fx.database.functions }

  it "creates both functions" do
    connection.create_function(:test)

    expect(functions[0].name).to eql("test")
    expect(functions[0].arguments).to eql("")

    expect(functions[1].name).to eql("test")
    expect(functions[1].arguments).to eql("str text")
  end

  it "drops both functions" do
    connection.create_function(:test)
    connection.drop_function(:test)

    expect(functions).to be_empty
  end
end
