require "rails"

module Fx
  module SchemaDumper
    # @api private
    module View
      def tables(stream)
        super
        views(stream)
        empty_line(stream)
      end

      def empty_line(stream)
        stream.puts if dumpable_view_in_database.any?
      end

      def views(stream)
        dumpable_view_in_database.each do |view|
          stream.puts(view.to_schema)
        end
      end

      private

      def dumpable_view_in_database
        @_dumpable_view_in_database ||= Fx.database.views
      end
    end
  end
end
