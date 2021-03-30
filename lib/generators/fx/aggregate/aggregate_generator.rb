require "rails/generators"
require "rails/generators/active_record"

module Fx
  module Generators
    # @api private
    class AggregateGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      def create_aggregates_directory
        unless aggregate_definition_path.exist?
          empty_directory(aggregate_definition_path)
        end
      end

      def create_aggregate_definition
        if creating_new_aggregate?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        if updating_existing_aggregate?
          migration_template(
            "db/migrate/update_aggregate.erb",
            "db/migrate/update_aggregate_#{file_name}_to_version_#{version}.rb",
          )
        else
          migration_template(
            "db/migrate/create_aggregate.erb",
            "db/migrate/create_aggregate_#{file_name}.rb",
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @_previous_version ||= Dir.entries(aggregate_definition_path).
            map { |name| version_regex.match(name).try(:[], "version").to_i }.
            max
        end

        def version
          @_version ||= previous_version.next
        end

        def migration_class_name
          if updating_existing_aggregate?
            "UpdateAggregate#{class_name}ToVersion#{version}"
          else
            super
          end
        end

        def activerecord_migration_class
          if ActiveRecord::Migration.respond_to?(:current_version)
            "ActiveRecord::Migration[5.0]"
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
      end

      private

      def aggregate_definition_path
        @_aggregate_definition_path ||= Rails.root.join(*%w(db aggregates))
      end

      def version_regex
        /\A#{file_name}_v(?<version>\d+)\.sql\z/
      end

      def updating_existing_aggregate?
        previous_version > 0
      end

      def creating_new_aggregate?
        previous_version == 0
      end

      def definition
        Fx::Definition.new(
          name: file_name,
          version: version,
          type: "aggregate"
        )
      end

      def previous_definition
        Fx::Definition.new(
          name: file_name,
          version: previous_version,
          type: "aggregate"
        )
      end
    end
  end
end
