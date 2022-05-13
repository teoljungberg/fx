module Fx
  # @return [Fx::Configuration] F(x)'s current configuration
  def self.configuration
    @_configuration ||= Configuration.new
  end

  # Set F(x)'s configuration
  #
  # @param config [Fx::Configuration]
  def self.configuration=(config)
    @_configuration = config
  end

  # Modify F(x)'s current configuration
  #
  # @yieldparam [Fx::Configuration] config current F(x) config
  # ```
  # Fx.configure do |config|
  #   config.database = Fx::Adapters::Postgres
  #   config.dump_functions_at_beginning_of_schema = true
  # end
  # ```
  def self.configure
    yield configuration
  end

  # F(x)'s configuration object.
  class Configuration
    # The F(x) database adapter instance to use when executing SQL.
    #
    # Defaults to an instance of {Fx::Adapters::Postgres}
    # @return Fx adapter
    attr_accessor :database

    # Prioritizes the order in the schema.rb of functions before other
    # statements in order to make directly schema load work when using functions
    # in statements below, i.e.: default column values.
    #
    # Defaults to false
    # @return Boolean
    attr_accessor :dump_functions_at_beginning_of_schema

    # A lambda returning a boolean to indicate whether or not a given trigger
    # should be allowed to be dumped into schema.rb
    #
    # Defaults to a lambda which allows all triggers
    # @return Proc<Boolean>
    attr_accessor :exclude_trigger_from_schema_condition

    # A lambda returning a boolean to indicate whether or not a given function
    # should be allowed to be dumped into schema.rb
    #
    # Defaults to a lambda which allows all function
    # @return Proc<Boolean>
    attr_accessor :exclude_function_from_schema_condition

    def initialize
      @database = Fx::Adapters::Postgres.new
      @dump_functions_at_beginning_of_schema = false
      @exclude_trigger_from_schema_condition = lambda { |trigger| false }
      @exclude_function_from_schema_condition = lambda { |function| false }
    end
  end
end
