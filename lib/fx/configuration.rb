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

    # Check function bodies during creation by issuing
    # `SET LOCAL check_function_bodies TO <<value>>;` before creating functions.
    #
    # See https://stackoverflow.com/a/36983831 and
    # https://www.postgresql.org/docs/9.5/runtime-config-client.html#GUC-CHECK-FUNCTION-BODIES
    #
    # Set to `nil` to use the database default configuration.
    # The default and recommended value is `false` to mimic pg_dump's behavior.
    #
    # Defaults to false
    # @return Boolean, nil
    attr_accessor :check_function_bodies

    def initialize
      @database = Fx::Adapters::Postgres.new
      @dump_functions_at_beginning_of_schema = false
      @check_function_bodies = false
    end
  end
end
