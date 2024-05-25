module Fx
  # @api private
  class Definition
    FUNCTION = "function".freeze
    TRIGGER = "trigger".freeze

    def self.function(name:, version:)
      new(name: name, version: version, type: FUNCTION)
    end

    def self.trigger(name:, version:)
      new(name: name, version: version, type: TRIGGER)
    end

    def initialize(name:, version:, type:)
      @name = name
      @version = version.to_i
      @type = type
    end

    def to_sql
      content = File.read(find_file || full_path)
      raise "Define #{@type} in #{path} before migrating." if content.empty?

      content
    end

    def full_path
      Rails.root.join(path)
    end

    def path
      @_path ||= File.join("db", @type.pluralize, filename)
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    def filename
      @_filename ||= "#{@name}_v#{version}.sql"
    end

    def find_file
      migration_paths.lazy
        .map { |migration_path| File.expand_path(File.join("..", "..", path), migration_path) }
        .find { |definition_path| File.exist?(definition_path) }
    end

    def migration_paths
      Rails.application.config.paths["db/migrate"].expanded
    end
  end
end
