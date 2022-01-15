require "rails"

module Fx
  # @api private
  module Migration

    def fx_migration_action(*arguments, &block)
      _method = __callee__
      arg_list = arguments.map(&:inspect) * ", "

      say_with_time "#{_method}(#{arg_list})" do
        unless connection.respond_to? :revert
          if !arguments.empty? && [:drop_trigger, :update_trigger].include?(_method)
            if arguments.second.is_a?(Hash) && arguments.second.key?(:on)
              on_table = arguments[1][:on]
              arguments[1] = arguments.second.merge(on: proper_table_name(on_table, table_name_options))
            end
          end
        end
        return super unless connection.respond_to?(_method)
        connection.send(_method, *arguments, &block)
      end
    end
    alias_method :create_function, :fx_migration_action
    alias_method :drop_function, :fx_migration_action
    alias_method :update_function, :fx_migration_action
    alias_method :create_trigger, :fx_migration_action
    alias_method :drop_trigger, :fx_migration_action
    alias_method :update_trigger, :fx_migration_action
  end
end
