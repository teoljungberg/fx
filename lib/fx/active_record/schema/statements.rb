require "rails"

module Fx
  module ActiveRecord
    module Schema
      module Statements
        def create_function(name, version = 1)
          execute function(name, version)
        end

        def drop_function(name, revert_to_version: nil)
          execute "DROP FUNCTION #{name}();"
        end

        def update_function(name, version)
          drop_function(name)
          create_function(name, version)
        end

        private

        def function(name, version)
          File.read ::Rails.root.join(
            "db",
            "functions",
            "#{name}_v#{version}.sql",
          )
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::ActiveRecord::Schema::Statements,
)
