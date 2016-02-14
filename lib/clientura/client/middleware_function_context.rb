module Clientura
  module Client
    class MiddlewareFunctionContext < SimpleDelegator
      attr_accessor :request, :instance, :args

      def initialize(request:, instance:, args:, callable:, config:)
        # headers
        # params
        # json
        # uri
        @request  = request
        @instance = instance
        @args     = args
        @callable = callable
        @config   = config

        super @request
      end

      def call
        instance_exec(*@config, &@callable)
      end
    end
  end
end
