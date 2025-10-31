require "rails/generators"
require "rails/generators/active_record"
require "fx/generators/version_helper"
require "fx/generators/migration_helper"
require "fx/generators/name_helper"

module Fx
  module Generators
    # @api private
    class TriggerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration

      source_root File.expand_path("../templates", __FILE__)
      argument :table_name, type: :hash, required: true

      DEFINITION_PATH = %w[db triggers].freeze

      class_option :migration, type: :boolean

      def create_triggers_directory
        return if trigger_definition_path.exist?

        empty_directory(trigger_definition_path)
      end

      def create_trigger_definition
        create_file(definition.path)
      end

      def create_migration_file
        return if migration_helper.skip_creation?

        template_info = migration_helper.migration_template_info(
          :trigger,
          file_name,
          version_helper.updating_existing?,
          version_helper.current_version
        )

        migration_template(template_info[:template], template_info[:filename])
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
              :trigger,
              class_name,
              version
            )
          else
            super
          end
        end

        def active_record_migration_class
          migration_helper.active_record_migration_class
        end

        def formatted_name
          NameHelper.format_for_migration(singular_name)
        end

        def formatted_table_name
          NameHelper.format_table_name_from_hash(table_name)
        end
      end

      private

      def trigger_definition_path
        @_trigger_definition_path ||= Rails.root.join(*DEFINITION_PATH)
      end

      def version_helper
        @_version_helper ||= VersionHelper.new(
          file_name,
          trigger_definition_path
        )
      end

      def migration_helper
        @_migration_helper ||= MigrationHelper.new(options)
      end

      def definition
        version_helper.definition_for_version(version, :trigger)
      end

      def updating_existing_trigger?
        version_helper.updating_existing?
      end
    end
  end
end
