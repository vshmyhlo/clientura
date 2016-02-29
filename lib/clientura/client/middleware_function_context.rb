module Clientura
  module Client
    class MiddlewareFunctionContext < SimpleDelegator
      attr_accessor :client, :args

      def initialize(request:, client:, args:, callable:, config:)
        @request  = request
        @client   = client
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
