require "rails/generators"
require "rails/generators/active_record"
require "generators/fx/version_helper"
require "generators/fx/migration_helper"
require "generators/fx/name_helper"

module Fx
  module Generators
    # @api private
    class FunctionGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)

      DEFINITION_PATH = %w[db functions].freeze

      class_option :migration, type: :boolean

      def create_functions_directory
        return if function_definition_path.exist?

        empty_directory(function_definition_path)
      end

      def create_function_definition
        if version_helper.creating_new?
          create_file(definition.path)
        else
          copy_file(previous_definition.full_path, definition.full_path)
        end
      end

      def create_migration_file
        return if migration_helper.skip_creation?

        template_info = migration_helper.migration_template_info(
          object_type: :function,
          file_name: file_name,
          updating_existing: version_helper.updating_existing?,
          version: version_helper.current_version
        )

        migration_template(
          template_info.fetch(:template),
          template_info.fetch(:filename)
        )
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          version_helper.previous_version
        end

        def version
          version_helper.current_version
        end

        def migration_class_name
          if version_helper.updating_existing?
            migration_helper.update_migration_class_name(
              object_type: :function,
              class_name: class_name,
              version: version
            )
          else
            super
          end
        end

        def formatted_name
          Fx::Generators::NameHelper.format_for_migration(singular_name)
        end
      end

      private

      def function_definition_path
        @_function_definition_path ||= Rails.root.join(*DEFINITION_PATH)
      end

      def version_helper
        @_version_helper ||= Fx::Generators::VersionHelper.new(
          file_name: file_name,
          definition_path: function_definition_path
        )
      end

      def migration_helper
        @_migration_helper ||= Fx::Generators::MigrationHelper.new(options)
      end

      def definition
        version_helper.definition_for_version(version: version, type: :function)
      end

      def previous_definition
        version_helper.definition_for_version(version: previous_version, type: :function)
      end

      def updating_existing_function?
        version_helper.updating_existing?
      end

      def creating_new_function?
        version_helper.creating_new?
      end
    end
  end
end
