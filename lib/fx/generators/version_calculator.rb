module Fx
  module Generators
    class VersionCalculator
      def initialize(file_name, definition_path)
        @file_name = file_name
        @definition_path = definition_path
      end

      def previous_version
        @_previous_version ||= calculate_previous_version
      end

      def current_version
        @_current_version ||= previous_version.next
      end

      def updating_existing?
        previous_version > 0
      end

      def creating_new?
        previous_version == 0
      end

      def version_glob_pattern
        "#{file_name}_v*.sql"
      end

      def definition_for_version(version, type)
        case type
        when :function
          Fx::Definition.function(name: file_name, version: version)
        when :trigger
          Fx::Definition.trigger(name: file_name, version: version)
        else
          raise ArgumentError, "Unknown type: #{type}. Must be :function or :trigger"
        end
      end

      private

      attr_reader :file_name, :definition_path

      def calculate_previous_version
        Dir.glob(version_glob_pattern, base: definition_path)
          .map { |filename| extract_version_from_filename(filename) }
          .compact
          .max || 0
      end

      def extract_version_from_filename(filename)
        match = filename.match(version_regex)
        match ? match["version"].to_i : nil
      end

      def version_regex
        /\A#{Regexp.escape(file_name)}_v(?<version>\d+)\.sql\z/
      end
    end
  end
end
