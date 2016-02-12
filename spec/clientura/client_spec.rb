describe Clientura::Client do
  subject { client }

  let(:uri) { 'http://localhost:3001' }
  let(:client) { klass.new(uri: uri, token: 'InitToken') }
  let(:klass) do
    Class.new do
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

    it { should eq 'data' => 'InitToken' }
  end

  describe 'configurable_uri_resource' do
    subject { client.configurable_uri_resource }

    it { should eq 'data' => 'resource' }
  end
end
