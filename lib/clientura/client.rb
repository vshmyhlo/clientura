require 'clientura/client/request'
require 'clientura/client/endpoint'

module Clientura
  module Client
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

      def get(name, path: nil, headers: {})
        register_endpoint(name, verb: :get,
                                path: path || name.to_s,
                                headers: headers)
      end

      def register_endpoint(name, verb:, path:, headers: {})
        registered_endpoints[name] = Endpoint.new verb,
                                                  path,
                                                  headers,
                                                  [*@middleware_context],
                                                  [*@pipes_context]

        define_method "#{name}_promise" do |**params|
          call_endpoint(name, params)
        end

        define_method name do |**params|
          send("#{name}_promise", params).value
        end
      end

      def pipe(name, callable)
        registered_pipes[name] = callable
      end

      def middleware(name, callable)
        registered_middleware[name] = callable
      end

      def pipe_through(*pipes)
        @pipes_context ||= []
        @pipes_context.push(*pipes)
        yield
        @pipes_context.pop pipes.count
      end

      def use_middleware(*middleware)
        @middleware_context ||= []
        @middleware_context.push(*middleware)
        yield
        @middleware_context.pop middleware.count
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

      attr_accessor :config

      def call_endpoint(name, **params)
        endpoint = registered_endpoints.fetch(name)

        path = if endpoint.path.respond_to?(:call)
                 endpoint.path.call(params)
               else
                 endpoint.path
               end

        headers = if endpoint.headers.respond_to?(:call)
                    endpoint.headers.call(params)
                  else
                    endpoint.headers
                  end

        http = endpoint.middleware.map do |middleware|
          case middleware
          when Array
            name, *args = middleware
            lambda do |http_, instance, params_|
              registered_middleware
                .fetch(name)
                .call(http_, instance, params_, *args)
            end
          else
            registered_middleware.fetch middleware
          end
        end.reduce Request.new do |http_, middleware|
          middleware.call http_, self, params
        end

        promise = Concurrent::Promise.execute do
          http.send(endpoint.verb, path, params: params)
        end

        endpoint.pipes.map do |pipe|
          case pipe
          when Array
            name, *args = pipe
            -> (res) { registered_pipes.fetch(name).call(res, *args) }
          else
            registered_pipes.fetch pipe
          end
        end.reduce promise do |promise_, pipe|
          promise_.then(&pipe)
        end
      end

      def full_path_for(path)
        URI.join URI.parse('http://127.0.0.1:3001'), path
      end
    end
  end
end
