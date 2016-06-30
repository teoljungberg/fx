module Fx
  class Function
    attr_reader :name, :definition
    delegate :<=>, to: :name

    def initialize(function_row)
      @name = function_row.fetch("proname")
      @definition = function_row.fetch("prosrc")
    end

    def ==(other)
      name == other.name && definition == other.definition
    end

    def to_schema
      <<~EOS
        create_function :#{name}, sql_definition: <<-\SQL
          #{definition}
        SQL
      EOS
    end
  end
end
