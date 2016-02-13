describe Clientura::Client do
  subject { client }

  let(:uri) { 'http://localhost:3001' }
  let(:client) { klass.new(uri: uri, token: 'InitializationToken') }
  let(:klass) do
    Class.new do
      include Clientura::Client

      middleware :static_token, -> (token) { request.headers(Token: token) }
      middleware :init_token, -> { request.headers(token: instance.config.fetch(:token)) }
      middleware :token_passer, -> { request.headers(token: params.fetch(:token)) }
      middleware :send_as_json, -> { request.update(:json) { params } }
      middleware :pass_as_query, -> { request.update(:params) { |p| p.merge params } }
      middleware :configurable_uri, lambda {
        request.update(:uri) { |uri_| URI.join instance.config.fetch(:uri), uri_ }
      }
      middleware :zip, lambda { |*endpoints|
        # super ugly :D

        Clientura.zip(*endpoints.map do |e|
          instance.send "#{e}_promise", params
        end) do |left, right|
          request.update(:json) { |p| p.merge sum: left + right }
        end
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
          use_middleware :send_as_json, [:zip, :left_operand, :right_operand] do
            post :sum
          end

          use_middleware :pass_as_query do
            get :left_operand
            get :right_operand
          end
        end
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

  describe 'Concurrent API' do
    describe '#sum' do
      context 'with valid key' do
        subject { client.sum key: 'Secret' }

        it { should eq true }
      end

      context 'with invalid key' do
        subject { -> { client.sum key: '' } }

        it { should raise_error(NoMethodError, "undefined method `+' for nil:NilClass") }
      end
    end

    describe '#sum_promise' do
      subject { client.sum_promise(key: 'Secret').value }

      it { should eq true }
    end
  end

  # it('__run_server__', :focus) { binding.pry }
end
