module Fx
  module Generators
    class PathHelper
      OBJECT_PATHS = {
        function: %w[db functions],
        trigger: %w[db triggers]
      }.freeze

      def self.definition_path_for(object_type)
        path_segments = OBJECT_PATHS[object_type]
        raise ArgumentError, "Unknown object type: #{object_type}" unless path_segments

        Rails.root.join(*path_segments)
      end

      def self.ensure_directory_exists(generator, path)
        generator.empty_directory(path) unless path.exist?
      end
    end
  end
end
