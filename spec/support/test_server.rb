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

  post '/data' do
    json data: JSON.parse(request.body.read)['json_data']
  end

  seed  = rand 50..100
  left  = rand 50
  right = seed - left

  get '/left_operand' do
    json data: params['key'] == 'Secret' ? left : nil
  end

  get '/right_operand' do
    json data: params['key'] == 'Secret' ? right : nil
  end

  post '/sum' do
    sum = JSON.parse(request.body.read)['sum']
    json data: seed == sum
  end
end
