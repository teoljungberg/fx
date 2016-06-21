require "rails"

module Fx
  module ActiveRecord
    module Schema
      module Statements
        def create_function(name)
          execute function(name)
        end

        def drop_function(name)
          execute "DROP FUNCTION #{name}();"
        end

        private

        def function(name)
          File.read ::Rails.root.join("db", "functions", "#{name}.sql")
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.send(
  :include,
  Fx::ActiveRecord::Schema::Statements,
)
