require "rails/generators"
require "rails/generators/active_record"

module Fx
  module Generators
    # @api private
    class TriggerGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)
      argument :table_name, type: :hash, required: true

      class_option :migration, type: :boolean

      def create_triggers_directory
        unless trigger_definition_path.exist?
          empty_directory(trigger_definition_path)
        end
      end

      def create_trigger_definition
        create_file definition.path
      end

      def create_migration_file
        return if skip_migration_creation?
        if updating_existing_trigger?
          migration_template(
            "db/migrate/update_trigger.erb",
            "db/migrate/update_trigger_#{file_name}_to_version_#{version}.rb"
          )
        else
          migration_template(
            "db/migrate/create_trigger.erb",
            "db/migrate/create_trigger_#{file_name}.rb"
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @_previous_version ||= Dir.entries(trigger_definition_path)
            .map { |name| version_regex.match(name).try(:[], "version").to_i }
            .max
        end

        def version
          @_version ||= previous_version.next
        end

        def migration_class_name
          if updating_existing_trigger?
            "UpdateTrigger#{class_name}ToVersion#{version}"
          else
            super
          end
        end

        def activerecord_migration_class
          if ActiveRecord::Migration.respond_to?(:current_version)
            "ActiveRecord::Migration[#{ActiveRecord::Migration.current_version}]"
          else
            "ActiveRecord::Migration"
          end
        end

        def formatted_name
          if singular_name.include?(".")
            "\"#{singular_name}\""
          else
            ":#{singular_name}"
          end
        end

        def formatted_table_name
          name = table_name["table_name"] || table_name["on"]

          if name.nil?
            raise(
              ArgumentError,
              "Either `table_name:NAME` or `on:NAME` must be specified"
            )
          end

          if name.include?(".")
            "\"#{name}\""
          else
            ":#{name}"
          end
        end
      end

      private

      def version_regex
        /\A#{file_name}_v(?<version>\d+)\.sql\z/
      end

      def updating_existing_trigger?
        previous_version > 0
      end

      def definition
        Fx::Definition.new(
          name: file_name,
          version: version,
          type: "trigger"
        )
      end

      def trigger_definition_path
        @_trigger_definition_path ||= Rails.root.join("db", "triggers")
      end

      # Skip creating migration file if:
      #   - migrations option is nil or false
      def skip_migration_creation?
        !migration
      end

      # True unless explicitly false
      def migration
        options[:migration] != false
      end
    end
  end
end
