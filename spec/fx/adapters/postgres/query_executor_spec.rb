require "spec_helper"

RSpec.describe Fx::Adapters::Postgres::QueryExecutor, :db do
  it "executes the query and maps results to objects" do
    connection = ActiveRecord::Base.connection
    query = "SELECT 'Hello World' as message, 'english' as language"
    greeter = Class.new do
      attr_reader :message, :language

      def initialize(row)
        @message = row.fetch("message")
        @language = row.fetch("language")
      end
    end

    results = described_class.call(
      connection: connection,
      query: query,
      model_class: greeter
    )

    expect(results.size).to eq(1)
    expect(results.first).to be_a(greeter)
    expect(results.first.message).to eq("Hello World")
    expect(results.first.language).to eq("english")
  end

  it "executes query with multiple results" do
    connection = ActiveRecord::Base.connection
    query = <<~SQL
        SELECT 'first' as name
        UNION ALL
        SELECT 'second' as name
        ORDER BY name
    SQL
    simple_name = Class.new do
      attr_reader :name

      def initialize(row)
        @name = row.fetch("name")
      end
    end

    results = described_class.call(
      connection: connection,
      query: query,
      model_class: simple_name
    )

    expect(results.size).to eq(2)
    expect(results).to all(be_a(simple_name))
    expect(results.first.name).to eq("first")
    expect(results.last.name).to eq("second")
  end

  it "returns an empty array when query returns no results" do
    connection = ActiveRecord::Base.connection
    query = "SELECT 'test' as name WHERE 1 = 0"
    simple_name = Class.new do
      attr_reader :name

      def initialize(row)
        @name = row.fetch("name")
      end
    end

    results = described_class.call(
      connection: connection,
      query: query,
      model_class: simple_name
    )

    expect(results).to eq([])
  end
end
