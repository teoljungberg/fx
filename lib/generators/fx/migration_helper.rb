module Fx
  module Generators
    # @api private
    class MigrationHelper
      def initialize(options)
        @options = options
      end

      def skip_creation?
        !should_create_migration?
      end

      def update_migration_class_name(object_type:, class_name:, version:)
        "Update#{object_type.capitalize}#{class_name}ToVersion#{version}"
      end

      def migration_template_info(
        object_type:,
        file_name:,
        updating_existing:,
        version:
      )
        if updating_existing
          {
            template: "db/migrate/update_#{object_type}.erb",
            filename: "db/migrate/update_#{object_type}_#{file_name}_to_version_#{version}.rb"
          }
        else
          {
            template: "db/migrate/create_#{object_type}.erb",
            filename: "db/migrate/create_#{object_type}_#{file_name}.rb"
          }
        end
      end

      private

      attr_reader :options

      def should_create_migration?
        options.fetch(:migration, true)
      end
    end
  end
end
