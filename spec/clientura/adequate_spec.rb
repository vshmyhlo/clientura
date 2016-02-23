describe 'Ability to use this for solving real world problems',
         test_server: :adequate do
  # Purpose of this spec is to define some real world use cases in a clean and
  # readable manner to serve as an example of usage.

  subject { instance }

  let(:instance) { client_class.new(client_config) }
  let(:client_config) { { uri: 'http://localhost:3001/real_world/' } }
  let(:client_class) do
    Class.new do
      include Clientura::Client

      middleware :configurable_uri, -> { update(:uri) { client.config[:uri] } }
      middleware :header_with_token, -> { headers AuthToken: client.config[:token] }
      middleware :pass_all_as_query_string, -> { update(:params) { args } }
      middleware :namespace, -> (namespace) { update(:uri) { |uri| URI.join uri, namespace } }

      pipe :body_retriever, -> (res) { res.body.to_s }
      pipe :parser, -> (res, parser) { parser.parse res }
      pipe :answer_header, -> (res) { res.headers['Answer'] }
      pipe :data_retriever, -> (res) { res['data'] }

      use_middleware :configurable_uri do
        get :root, path: '/'

        use_middleware :header_with_token do
          get :pass_token
        end

        pipe_through :body_retriever do
          pipe_through [:parser, JSON] do
            get :parse_response

            pipe_through :data_retriever do
              get :comments, path: -> (params) { "comments/#{params[:id]}" }
              get :users, path: -> (params) { "users/#{params[:id]}" }
              get :attachments, path: -> (params) { "attachments/#{params[:id]}" }
            end
          end

          use_middleware :pass_all_as_query_string do
            get :pass_query_string
          end
        end

        use_middleware [:namespace, 'namespace/'] do
          get :namespaced
        end

        pipe_through :answer_header do
          get :get_answer_header
        end
      end

      def initialize(uri:, token: nil)
        save_config uri: uri, token: token
      end
    end
  end

  describe 'My wish to see this at least working' do
    subject { super().root.status }

    it { should eq 200 }
  end

  describe 'My desire to pass some token in header' do
    subject { super().pass_token.status }

    let(:client_config) { super().merge token: token }

    context 'when token is bad' do
      let(:token) { 'Bad token!' }

      it { should eq 403 }
    end

    context 'when token is good' do
      let(:token) { 'Secret' }

      it { should eq 200 }
    end
  end

  describe 'My desire to parse response' do
    subject { super().parse_response }

    it { should eq 'data' => 'Awesome!' }
  end

  describe 'My desire to pass query string' do
    subject { super().pass_query_string echo: 'Awesome!' }

    it { should eq 'Awesome!' }
  end

  describe 'My desire to get response header' do
    subject { super().get_answer_header }

    it { should eq 'Awesome!' }
  end

  describe 'My desire to namespace routes' do
    subject { super().namespaced.status }

    it { should eq 200 }
  end
end
