module Fx
  module Generators
    # @api private
    class NameHelper
      def self.format_for_migration(name)
        if name.include?(".")
          "\"#{name}\""
        else
          ":#{name}"
        end
      end

      def self.format_table_name_from_hash(table_hash)
        name = table_hash["table_name"] || table_hash["on"]

        if name.nil?
          raise ArgumentError, "Either `table_name:NAME` or `on:NAME` must be specified"
        end

        format_for_migration(name)
      end

      def self.validate_and_format(name)
        raise ArgumentError, "Name cannot be blank" if name.blank?

        format_for_migration(name)
      end
    end
  end
end
