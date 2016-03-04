require 'clientura/client/request'
require 'clientura/client/endpoint'
require 'clientura/client/middleware_function_context'

module Clientura
  module Client
    def self.included(klass)
      klass.extend ClassMethods
      klass.include InstanceMethods
    end

    module ClassMethods
      def registered_endpoints
        @registered_endpoints ||= {}
      end

      def registered_pipes
        @registered_pipes ||= {}
      end

      def registered_middleware
        @registered_middleware ||= {}
      end

      [:get, :post, :put, :patch, :delete].each do |verb|
        define_method verb do |name, path: nil|
          register_endpoint(name, verb: verb, path: path || name.to_s)
        end
      end

      def normalize_path(path)
        if path.respond_to?(:call)
          path
        else
          -> (_) { path }
        end
      end

      def register_endpoint(name, verb:, path:)
        registered_endpoints[name] = Endpoint.new verb,
                                                  normalize_path(path),
                                                  [*@middleware_context],
                                                  [*@pipes_context]

        define_method name do |args = {}|
          call_endpoint name, args
        end

        define_method "#{name}_promise" do |args = {}|
          Concurrent::Promise.execute { send(name, args) }
        end
      end

      def pipe(name, callable)
        registered_pipes[name] = callable
      end

      def middleware(name, callable)
        registered_middleware[name] = callable
      end

      def pipe_through(*pipes)
        pipes = pipes.map { |o| normalize_mapper o }

        @pipes_context ||= []
        @pipes_context.push(*pipes)
        yield
        @pipes_context.pop pipes.count
      end

      def use_middleware(*middleware)
        middleware = middleware.map { |o| normalize_mapper o }

        @middleware_context ||= []
        @middleware_context.push(*middleware)
        yield
        @middleware_context.pop middleware.count
      end

      def normalize_mapper(mapper)
        case mapper
        when Array
          name, *config = mapper
          { name: name, config: config }
        else
          { name: mapper, config: [] }
        end
      end
    end

    module InstanceMethods
      def self.included(klass)
        define_method :registered_endpoints do
          klass.registered_endpoints
        end

        define_method :registered_pipes do
          klass.registered_pipes
        end

        define_method :registered_middleware do
          klass.registered_middleware
        end
      end

      attr_writer :config

      def config
        @config ||= {}
      end

      def save_config(args)
        self.config = config.merge args
      end

      def call_endpoint(name_, args)
        endpoint = registered_endpoints.fetch name_

        middlewares = endpoint.middleware.map do |name:, config:|
          { callable: registered_middleware.fetch(name), config: config }
        end

        request = middlewares
                  .reduce Request.new do |request_, callable:, config:|
          middleware = MiddlewareFunctionContext.new(request: request_,
                                                     client: self,
                                                     args: args,
                                                     callable: callable,
                                                     config: config)
          middleware.call
        end

        response = request.send endpoint.verb, endpoint.path.call(args)

        endpoints = endpoint.pipes.map do |name:, config:|
          -> (res) { registered_pipes.fetch(name).call(res, *config) }
        end

        endpoints.reduce response do |response_, pipe|
          pipe.call response_
        end
      end
    end
  end
end
