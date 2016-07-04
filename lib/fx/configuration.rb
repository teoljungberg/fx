module Fx
  def self.configuration
    @_configuration ||= Configuration.new
  end

  def self.configuration=(config)
    @_configuration = config
  end

  def self.configure
    yield configuration
  end

  class Configuration
    attr_accessor :database

    def initialize
      @database = Fx::Adapters::Postgres
    end
  end
end
