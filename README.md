# clientura

specs example
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :static_token, -> (req, *_, token) { req.headers(Token: token) }
  middleware :init_token, -> (req, instance, *_) { req.headers(token: instance.config.fetch(:token)) }
  middleware :token_passer, -> (req, *_, params) { req.headers(token: params.fetch(:token)) }
  middleware :configurable_uri, lambda { |req, instance, *_|
    req.update(:uri) { |uri_| URI.join instance.config.fetch(:uri), uri_ }
  }

  pipe :body_retriever, -> (res) { res.body.to_s }
  pipe :parser, -> (res, parser) { parser.parse res }

  use_middleware :configurable_uri do
    pipe_through :body_retriever do
      get :resource_raw, path: 'res'

      pipe_through [:parser, JSON] do
        get :root, path: '/'
        get :resource, path: 'res'
        get :name
        get :echo_argument, path: -> (params) { "echo_argument/#{params[:argument]}" }
        get :echo_param
      end
    end

    pipe_through :body_retriever, [:parser, JSON] do
      use_middleware [:static_token, 'StaticToken'] do
        get :try_static_token, path: 'echo_header'
      end

      use_middleware [:static_token, 'Token'] do
        get :echo_header_const, path: 'echo_header'
      end

      use_middleware :token_passer do
        get :try_token_passer, path: 'echo_header'
        get :echo_header
      end

      use_middleware :init_token do
        get :try_init_token, path: 'echo_header'
      end

      get :configurable_uri_resource, path: 'res'
    end
  end

  def initialize(uri:, token:)
    self.config = {
      uri: URI.parse(uri),
      token: token
    }
  end
end
```