module Fx
  # A database trigger to dump into `schema.rb`.
  #
  # Part of the public adapter interface: adapters return instances of
  # this class from `triggers`. The constructor takes a row (anything
  # responding to `#fetch`, such as a `Hash`) with `"name"` and
  # `"definition"` keys.
  class Trigger
    include Comparable

    # @return [String] the name of the trigger
    attr_reader :name

    # @return [String] the SQL definition of the trigger
    attr_reader :definition

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
