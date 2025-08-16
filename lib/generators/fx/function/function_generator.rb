require "rails/generators"
require "rails/generators/active_record"
require "fx/generators/version_calculator"
require "fx/generators/migration_helper"
require "fx/generators/name_formatter"
require "fx/generators/path_helper"

module Fx
  module Generators
    # @api private
    class FunctionGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      class_option :migration, type: :boolean

      def create_functions_directory
        PathHelper.ensure_directory_exists(self, function_definition_path)
      end

      def create_function_definition
        if version_calculator.creating_new?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        return if migration_helper.skip_creation?

        template_info = migration_helper.migration_template_info(
          :function,
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
            migration_helper.update_migration_class_name(:function, class_name, version)
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
      end

      private

      def function_definition_path
        @_function_definition_path ||= PathHelper.definition_path_for(:function)
      end

      def version_calculator
        @_version_calculator ||= VersionCalculator.new(file_name, function_definition_path)
      end

      def migration_helper
        @_migration_helper ||= MigrationHelper.new(options)
      end

      def definition
        version_calculator.definition_for_version(version, :function)
      end

      def previous_definition
        version_calculator.definition_for_version(previous_version, :function)
      end

      def updating_existing_function?
        version_calculator.updating_existing?
      end

      def creating_new_function?
        version_calculator.creating_new?
      end
    end
  end
end
