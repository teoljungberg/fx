require "rails/generators"
require "rails/generators/active_record"

module Fx
  module Generators
    # @api private
    class ViewGenerator < Rails::Generators::NamedBase
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      class_option :materialized, type: :boolean, default: false
      class_option :migration, type: :boolean

      def create_views_directory
        unless view_definition_path.exist?
          empty_directory(view_definition_path)
        end
      end

      def create_view_definition
        if creating_new_view?
          create_file definition.path
        else
          copy_file previous_definition.full_path, definition.full_path
        end
      end

      def create_migration_file
        return if skip_migration_creation?
        if updating_existing_view?
          migration_template(
            "db/migrate/update_view.erb",
            "db/migrate/update_view_#{file_name}_to_version_#{version}.rb"
          )
        else
          migration_template(
            "db/migrate/create_view.erb",
            "db/migrate/create_view_#{file_name}.rb"
          )
        end
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end

      no_tasks do
        def previous_version
          @_previous_version ||= Dir.entries(view_definition_path)
            .map { |name| version_regex.match(name).try(:[], "version").to_i }
            .max
        end

        def version
          @_version ||= previous_version.next
        end

        def materialized?
          options[:materialized]
        end

        alias_method :original_file_name, :file_name
        def file_name
          super.tr(".", "_")
        end

        def singular_name
          original_file_name
        end

        def migration_class_name
          if updating_existing_view?
            "UpdateView#{class_name}ToVersion#{version}"
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
      end

      private

      def view_definition_path
        @_view_definition_path ||= Rails.root.join(*%w[db views])
      end

      def version_regex
        /\A#{file_name}_v(?<version>\d+)\.sql\z/
      end

      def updating_existing_view?
        previous_version > 0
      end

      def creating_new_view?
        previous_version == 0
      end

      def definition
        Fx::Definition.new(
          name: file_name,
          version: version,
          type: "view"
        )
      end

      def previous_definition
        Fx::Definition.new(
          name: file_name,
          version: previous_version,
          type: "view"
        )
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
