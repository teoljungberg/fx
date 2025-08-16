require "rails/generators"
require "rails/generators/active_record"
require "fx/generators/version_calculator"
require "fx/generators/migration_helper"
require "fx/generators/name_formatter"
require "fx/generators/path_helper"

module Fx
  module Generators
    # @api private
    class TriggerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)
      argument :table_name, type: :hash, required: true

      class_option :migration, type: :boolean

      def create_triggers_directory
        PathHelper.ensure_directory_exists(self, trigger_definition_path)
      end

      def create_trigger_definition
        create_file definition.path
      end

      def create_migration_file
        return if migration_helper.skip_creation?

        template_info = migration_helper.migration_template_info(
          :trigger,
          file_name,
          version_calculator.updating_existing?,
          version_calculator.current_version
        )

        migration_template(template_info[:template], template_info[:filename])
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          version_calculator.previous_version
        end

        def version
          version_calculator.current_version
        end

        def migration_class_name
          if version_calculator.updating_existing?
            migration_helper.update_migration_class_name(:trigger, class_name, version)
          else
            super
          end
        end

        def activerecord_migration_class
          migration_helper.activerecord_migration_class
        end

        def formatted_name
          NameFormatter.format_for_migration(singular_name)
        end

        def formatted_table_name
          NameFormatter.format_table_name_from_hash(table_name)
        end
      end

      private

      def trigger_definition_path
        @_trigger_definition_path ||= PathHelper.definition_path_for(:trigger)
      end

      def version_calculator
        @_version_calculator ||= VersionCalculator.new(file_name, trigger_definition_path)
      end

      def migration_helper
        @_migration_helper ||= MigrationHelper.new(options)
      end

      def definition
        version_calculator.definition_for_version(version, :trigger)
      end

      def updating_existing_trigger?
        version_calculator.updating_existing?
      end
    end
  end
end
