# clientura

example from specs
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :static_token, -> (token) { headers(Token: token) }
  middleware :init_token, -> { headers(token: client.config[:token]) }
  middleware :token_passer, -> { headers(token: args[:token]) }
  middleware :send_as_json, -> { update(:json) { args } }
  middleware :pass_as_query, -> { update(:params) { |p| p.merge args } }
  middleware :configurable_uri, lambda {
    update(:uri) { |uri| URI.join client.config[:uri], uri }
  }

  pipe :body_retriever, -> (res) { res.body.to_s }
  pipe :parser, -> (res, parser) { parser.parse res }
  pipe :data_retriever, -> (res) { res['data'] }

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

  use_middleware :configurable_uri do
    pipe_through :body_retriever, [:parser, JSON], :data_retriever do
      use_middleware :send_as_json do
        post :sum
      end

      get :comments, path: -> (params) { "comments/#{params[:id]}" }
      get :users, path: -> (params) { "users/#{params[:id]}" }
      get :tags, path: -> (params) { "tags/#{params[:id]}" }

      use_middleware :pass_as_query do
        get :left_operand
        get :right_operand
      end
    end
  end

  aggregator :fetch_sum do |key:|
    Clientura::RaisingPromise
      .zip(left_operand_promise(key: key), right_operand_promise(key: key))
      .then { |left, right| sum sum: left + right }
      .value
  end

  aggregator :fetch_comment do |id:|
    c = comments id: id
    user_id, tag_id = c.values_at 'user_id', 'tag_id'
    u, t = Clientura::RaisingPromise
           .zip(users_promise(id: user_id), tags_promise(id: tag_id)).value

    { 'comment' => c,
      'user' => u,
      'tag' => t }
  end

  def initialize(uri:, token:)
    save_config uri: URI.parse(uri), token: token
  end
end
```