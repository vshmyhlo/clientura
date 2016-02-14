module Clientura
  module Client
    class MiddlewareFunctionContext < SimpleDelegator
      attr_accessor :request, :instance, :params

      def initialize(request:, instance:, params:, callable:, arguments:)
        # headers
        # params
        # json
        # uri
        @request   = request
        @instance  = instance
        @params    = params
        @callable  = callable
        @arguments = arguments

        super @request
      end

      def call
        instance_exec(*@arguments, &@callable)
      end
    end
  end
end
