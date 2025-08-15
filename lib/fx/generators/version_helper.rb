module Fx
  module Generators
    # @api private
    class VersionHelper
      def initialize(file_name, definition_path)
        @file_name = file_name
        @definition_path = definition_path
      end

      def previous_version
        @previous_version ||= existing_versions.max || 0
      end

      def current_version
        previous_version.next
      end

      def updating_existing?
        previous_version > 0
      end

      def creating_new?
        previous_version == 0
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

      VERSION_PATTERN = /v(\d+)/
      private_constant :VERSION_PATTERN

      attr_reader :file_name, :definition_path

      def existing_versions
        Dir
          .glob("#{file_name}_v*.sql", base: definition_path)
          .map { |f| f[VERSION_PATTERN, 1].to_i }
          .compact
      end
    end
  end
end
