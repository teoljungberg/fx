require "fx/command_recorder/inversion"

module Fx
  module CommandRecorder
    # Translates between Active Record's pre-8.2 command shape, where keyword
    # arguments travel as a trailing hash flagged as keywords, and
    # {Fx::CommandRecorder::Inversion}.
    #
    # @api private
    module LegacyInversion
      # @param command [Symbol] a recorded fx command, such as `:create_function`
      # @param args [Array] recorded arguments, with any keyword arguments
      #   folded into a trailing hash flagged as keywords
      # @return [Array(Symbol, Array)] the command that undoes it
      def self.invert(command, args)
        inverse, inverse_args, inverse_kwargs = Fx::CommandRecorder::Inversion.invert(command, *split(args))

        [inverse, fold(inverse_args, inverse_kwargs)]
      end

      # Folds keyword arguments into a trailing hash flagged as keywords, so
      # `CommandRecorder#replay` passes them on as keywords.
      def self.fold(args, kwargs)
        if kwargs.empty?
          args
        else
          [*args, Hash.ruby2_keywords_hash(kwargs)]
        end
      end

      def self.split(args)
        if args.last.is_a?(Hash)
          [args[0...-1], args.last]
        else
          [args, {}]
        end
      end
      private_class_method :split
    end
  end
end
