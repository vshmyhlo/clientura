module Clientura
  module Client
    class MiddlewareFunctionContext
      attr_accessor :request, :instance, :params

      def initialize(request:, instance:, params:, callable:, arguments:)
        @request   = request
        @instance  = instance
        @params    = params
        @callable  = callable
        @arguments = arguments
      end

      def call
        instance_exec(*@arguments, &@callable)
      end
    end
  end
end
