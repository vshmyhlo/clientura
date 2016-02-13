# clientura

specs example
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :static_token, -> (token) { request.headers(Token: token) }
  middleware :init_token, -> { request.headers(token: instance.config.fetch(:token)) }
  middleware :token_passer, -> { request.headers(token: params.fetch(:token)) }
  middleware :send_as_json, -> { request.update(:json) { params } }
  middleware :pass_as_query, -> { request.update(:params) { |p| p.merge params } }
  middleware :configurable_uri, lambda {
    request.update(:uri) { |uri_| URI.join instance.config.fetch(:uri), uri_ }
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

        use_middleware :pass_as_query do
          get :echo_param
        end
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

      use_middleware :send_as_json do
        post :send_json, path: 'data'
      end
    end
  end

  def initialize(uri:, token:)
    save_config uri: URI.parse(uri), token: token
  end
end
```