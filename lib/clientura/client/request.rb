module Clientura
  module Client
    class Request < SimpleDelegator
      attr_reader :config, :http

      def initialize(http = HTTP.headers({}), config = { uri: '' })
        super http
        @http   = http
        @config = config
      end

      def update(key)
        Request.new http, config.merge(key => yield(config.fetch(key)))
      end

      def get(path, *args)
        super URI.join(config.fetch(:uri), path), *args
      end

      def headers(*args)
        Request.new(http.headers(*args), config)
      end
    end

    def self.included(klass)
      klass.extend ClassMethods
      klass.include InstanceMethods
    end
  end
end
