module Fx
  # @api private
  class Definition
    def initialize(name:, version:, type: "function")
      @name = name
      @version = version.to_i
      @type = type
    end

    def to_sql
      File.read(find_file || full_path).tap do |content|
        if content.empty?
          raise "Define #{@type} in #{path} before migrating."
        end
      end
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
      @_filename ||= "#{@name.to_s.tr(".", "_")}_v#{version}.sql"
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
