require "rails/generators"
require "rails/generators/active_record"

module Fx
  module Generators
    class FunctionGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)
      argument :function_name, type: :string

      def create_function_definition
        create_file "db/functions/#{function_name}_v1.sql"
      end

      def create_migration_file
        migration_template(
          "db/migrate/create_function.erb",
          "db/migrate/create_#{function_name}.rb"
        )
      end

      def self.next_migration_number(dir)
        ::ActiveRecord::Generators::Base.next_migration_number(dir)
      end
    end
  end
end
