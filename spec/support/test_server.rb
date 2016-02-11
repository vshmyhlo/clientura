class TestServer < Sinatra::Base
  get '/' do
    json data: 'root'
  end

  get '/res' do
    json data: 'resource'
  end

  get '/name' do
    json data: 'name'
  end

  get '/echo_argument/:argument' do
    json data: params[:argument]
  end

  get '/echo_header' do
    json data: env['HTTP_TOKEN']
  end

  get '/echo_param' do
    json data: params['param']
  end
end
