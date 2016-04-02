describe 'Ability to use this for solving real world problems' do
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
      middleware :bad_middleware, -> { raise 'Some Exception' }
      middleware :slow_middleware, -> { sleep 0.1; self }

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
          get :get_some, path: 'some'
          put :put_some, path: 'some'
          patch :patch_some, path: 'some'
          post :post_some, path: 'some'
          delete :delete_some, path: 'some'

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

      use_middleware :bad_middleware do
        get :raise_some_exception
      end

      use_middleware :slow_middleware, :bad_middleware do
        get :slowly_raise_some_exception
      end

      def initialize(uri:, token: nil)
        save_config uri: uri, token: token
      end
    end
  end

  describe 'My wish to see this at least working' do
    subject { super().root.code }

    it { should eq 200 }
  end

  describe 'My desire to use different verbs' do
    describe 'GET' do
      subject { super().get_some }

      it { should eq 'get' }
    end

    describe 'POST' do
      subject { super().post_some }

      it { should eq 'post' }
    end

    describe 'PUT' do
      subject { super().put_some }

      it { should eq 'put' }
    end

    describe 'PATCH' do
      subject { super().patch_some }

      it { should eq 'patch' }
    end

    describe 'DELETE' do
      subject { super().delete_some }

      it { should eq 'delete' }
    end
  end

  describe 'My desire to see some exceptions' do
    subject { -> { instance.raise_some_exception } }

    it { should raise_error 'Some Exception' }
  end

  describe 'My desire to work with promise' do
    context 'when no errors raised' do
      subject { super().root_promise }

      it { should be_pending }

      it 'has correct value' do
        expect(subject.value.code).to eq 200
      end

      context 'when awaited' do
        before { subject.value }

        it 'fulfills' do
          expect(subject).to be_fulfilled
        end
      end
    end

    context 'when error raised' do
      subject { super().slowly_raise_some_exception_promise }

      it { should be_pending }

      it 'has nil value' do
        expect(subject.value).to be nil
      end

      context 'when awaited' do
        before { subject.value }

        it 'rejects' do
          expect(subject).to be_rejected
        end

        it 'has correct message' do
          expect(subject.reason.message).to eq 'Some Exception'
        end
      end
    end
  end

  describe 'My desire to pass some token in header' do
    subject { super().pass_token.code }

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
    subject { super().namespaced.code }

    it { should eq 200 }
  end
end
