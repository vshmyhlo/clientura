describe Clientura::Client do
  subject { client }

  let(:uri) { 'http://localhost:3001' }
  let(:client) { klass.new(uri: uri, token: 'InitializationToken') }
  let(:klass) do
    Class.new do
      include Clientura::Client

      middleware :static_token, -> (token) { headers(Token: token) }
      middleware :init_token, -> { headers(token: instance.config[:token]) }
      middleware :token_passer, -> { headers(token: args[:token]) }
      middleware :send_as_json, -> { update(:json) { args } }
      middleware :pass_as_query, -> { update(:params) { |p| p.merge args } }
      middleware :configurable_uri, lambda {
        update(:uri) { |uri_| URI.join instance.config[:uri], uri_ }
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
  end

  describe '#root' do
    subject { client.root }

    it { should eq 'data' => 'root' }
  end

  describe '#resource' do
    subject { client.resource }

    it { should eq 'data' => 'resource' }
  end

  describe '#name' do
    subject { client.name }

    it { should eq 'data' => 'name' }
  end

  describe '#echo_argument' do
    subject { client.echo_argument argument: 'Argument' }

    it { should eq 'data' => 'Argument' }
  end

  describe '#echo_param' do
    subject { client.echo_param param: 'Param' }

    it { should eq 'data' => 'Param' }
  end

  describe '#echo_header' do
    subject { client.echo_header token: 'Token' }

    it { should eq 'data' => 'Token' }
  end

  describe '#echo_header_const' do
    subject { client.echo_header_const }

    it { should eq 'data' => 'Token' }
  end

  describe '#resource_raw' do
    subject { client.resource_raw }

    it { should eq JSON.dump data: 'resource' }
  end

  describe 'try_static_token' do
    subject { client.try_static_token }

    it { should eq 'data' => 'StaticToken' }
  end

  describe 'try_token_passer' do
    subject { client.try_token_passer token: 'PassedToken' }

    it { should eq 'data' => 'PassedToken' }
  end

  describe 'try_init_token' do
    subject { client.try_init_token }

    it { should eq 'data' => 'InitializationToken' }
  end

  describe 'configurable_uri_resource' do
    subject { client.configurable_uri_resource }

    it { should eq 'data' => 'resource' }
  end

  describe '#send_json' do
    subject { client.send_json json_data: { foo: :bar } }

    it { should eq 'data' => { 'foo' => 'bar' } }
  end

  describe '#sum' do
    subject { client.sum sum: sum }

    let(:sum) { client.left_operand(key: 'Secret') + client.right_operand(key: 'Secret') }

    it { should eq true }
  end

  describe '#fetch_sum' do
    subject { -> { client.fetch_sum key: key } }

    context 'with valid key' do
      subject { super().call }

      let(:key) { 'Secret' }

      it { should be true }
    end

    context 'with invalid key' do
      let(:key) { '' }

      it { should raise_error(NoMethodError, "undefined method `+' for nil:NilClass") }
    end
  end

  describe '#fetch_comment' do
    subject { client.fetch_comment id: 1 }

    it 'should return correct data' do
      should eq('comment' => {
                  'id' => '1',
                  'user_id' => '2',
                  'tag_id' => '3'
                },
                'user' => {
                  'id' => '2'
                },
                'tag' => {
                  'id' => '3'
                })
    end
  end

  # it('__run_server__', :focus) { binding.pry }
end
