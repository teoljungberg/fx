module Fx
  # Domain object representing a database trigger.
  #
  # Adapters return instances of this class from their {#triggers} method so
  # that {Fx::SchemaDumper} can serialize them into `schema.rb`.
  class Trigger
    include Comparable

    attr_reader :name, :definition
    delegate :<=>, to: :name

    def initialize(row)
      @name = row.fetch("name")
      @definition = row.fetch("definition")
    end

    def ==(other)
      name == other.name && definition == other.definition
    end

    def to_schema
      <<-SCHEMA
  create_trigger :#{name}, sql_definition: <<-\SQL
      #{definition}
  SQL
      SCHEMA
    end
  end
end
