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
      @path ||= File.join("db", @type.pluralize, filename)
    end

    def version
      @version.to_s.rjust(2, "0")
    end

    private

    def filename
      @filename ||= "#{@name}_v#{version}.sql"
    end

    def find_file
      Rails.application.config.paths["db/migrate"].each do |db_migrate_path|
        file_path = File.absolute_path(File.join(db_migrate_path, "..", "..", path))
        return file_path if File.exist?(file_path)
      end

      nil
    end
  end
end
