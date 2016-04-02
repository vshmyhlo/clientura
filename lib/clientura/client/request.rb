module Clientura
  module Client
    class Request
      attr_reader :config, :http

      def initialize(options = { uri: '', headers: {}, params: {} })
        @options = options
      end

      def update(key)
        Request.new @options.merge key => yield(@options[key])
      end

      def call
        uri            = @options[:uri]
        path           = @options[:path]
        json           = @options[:json]
        options        = @options.slice(*@options.keys - [:uri, :path, :json])
        options[:body] = JSON.dump(json) if json
        Typhoeus::Request.new(URI.join(uri, path), options).run
      end

      def headers(args)
        update(:headers) { |h| h.merge args }
      end
    end
  end
end
