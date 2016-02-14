module Clientura
  module Client
    class Request < SimpleDelegator
      attr_reader :config, :http

      def initialize(http = HTTP.headers({}),
                     config = { uri: '', params: {}, json: nil })
        super http
        @http   = http
        @config = config
      end

      def update(key)
        Request.new http, config.merge(key => yield(config.fetch(key)))
      end

      def get(path, **opts)
        super(*build_request_arguments(path, opts))
      end

      def post(path, **opts)
        super(*build_request_arguments(path, opts))
      end

      def build_request_arguments(path, **opts)
        opts[:params] = config.fetch(:params) if config[:params].present?
        opts[:json] = config.fetch(:json) if config[:json].present?
        [URI.join(config.fetch(:uri), path), opts]
      end

      def headers(*args)
        Request.new(http.headers(*args), config)
      end
    end
  end
end
