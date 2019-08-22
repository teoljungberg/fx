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
  #   config.define_functions_at_schema_beginning = true
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

    # Configuration flag that prioritizes the order in the schema.rb of triggers and functions before other statements
    # in order to make directly schema load work when using functions in statements below.
    #
    # Defaults false
    # @return Bool
    attr_accessor :define_functions_at_schema_beginning

    def initialize
      @database = Fx::Adapters::Postgres.new
      @define_functions_at_schema_beginning = false
    end
  end
end
