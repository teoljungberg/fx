module Fx
  # @api private
  module CommandRecorder
    def create_function(*args, &block)
      record(:create_function, args, &block)
    end
    ruby2_keywords :create_function if respond_to?(:ruby2_keywords, true)

    def drop_function(*args, &block)
      record(:drop_function, args, &block)
    end
    ruby2_keywords :drop_function if respond_to?(:ruby2_keywords, true)

    def update_function(*args, &block)
      record(:update_function, args, &block)
    end
    ruby2_keywords :update_function if respond_to?(:ruby2_keywords, true)

    def invert_create_function(args)
      [:drop_function, args]
    end

    def invert_drop_function(args)
      perform_inversion(:create_function, args)
    end

    def invert_update_function(args)
      perform_inversion(:update_function, args)
    end

    def create_trigger(*args, &block)
      record(:create_trigger, args, &block)
    end
    ruby2_keywords :create_trigger if respond_to?(:ruby2_keywords, true)

    def drop_trigger(*args, &block)
      record(:drop_trigger, args, &block)
    end
    ruby2_keywords :drop_trigger if respond_to?(:ruby2_keywords, true)

    def update_trigger(*args, &block)
      record(:update_trigger, args, &block)
    end
    ruby2_keywords :update_trigger if respond_to?(:ruby2_keywords, true)

    def invert_create_trigger(args)
      [:drop_trigger, args]
    end

    def invert_drop_trigger(args)
      perform_inversion(:create_trigger, args)
    end

    def invert_update_trigger(args)
      perform_inversion(:update_trigger, args)
    end

    private

    MESSAGE_IRREVERSIBLE = "`%s` is reversible only if given a `revert_to_version`".freeze

    def perform_inversion(method, args)
      arguments = Arguments.new(args)

      if arguments.revert_to_version.nil?
        raise ActiveRecord::IrreversibleMigration, format(MESSAGE_IRREVERSIBLE, method)
      end

      [method, arguments.invert_version.to_a]
    end

    class Arguments
      def initialize(args)
        @args = args.freeze
      end

      def function
        args.fetch(0)
      end

      def version
        options.fetch(:version)
      end

      def revert_to_version
        options.fetch(:revert_to_version, nil)
      end

      def invert_version
        self.class.new([function, options_for_revert])
      end

      def to_a
        args.to_a
      end

      private

      attr_reader :args

      def options
<<<<<<< HEAD
        @options ||= args[1] || {}
=======
        @options ||= args.fetch(1, {}).dup
>>>>>>> cc4da33 (Use attr_reader + .fetch)
      end

      def options_for_revert
        opts = options.clone.tap do |revert_options|
          revert_options[:version] = revert_to_version
          revert_options.delete(:revert_to_version)
        end

        keyword_hash(opts)
      end

      def keyword_hash(hash)
        if Hash.respond_to?(:ruby2_keywords_hash)
          Hash.ruby2_keywords_hash(hash)
        else
          hash
        end
      end
    end
    private_constant :Arguments
  end
end
