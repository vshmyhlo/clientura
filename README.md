# Clientura

### Basic concepts

Create client class
``` ruby 
class RandomApiClient
  include Clientura::Client
end
```
Define middleware (blocks which can be composed to configure your request before it is sent)
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :with_token, -> { headers(token: client.config[:token]) }
end
```
Define pipes (blocks which can be composed to process response)
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :with_token, -> { headers(token: client.config[:token]) }

  pipe :body_retriever, -> (res) { res.body.to_s }
  pipe :parser, -> (res, parser) { parser.parse res }
  pipe :data_retriever, -> (res) { res['data'] }
end
```
Compose this stuff!
```ruby
class RandomApiClient
  include Clientura::Client

  middleware :with_token, -> { headers(token: client.config[:token]) }

  pipe :body_retriever, -> (res) { res.body.to_s }
  pipe :parser, -> (res, parser) { parser.parse res }
  pipe :data_retriever, -> (res) { res['data'] }

  use_middleware :with_token do
    pipe_through :body_retriever, [:parser, JSON], :data_retriever do
      get :random_api_endpoint
      get :same_with_custom_path, path: 'super-custom-path'
      get :same_with_dynamic_path, path: -> (params) { "users/#{params[:id]}"}
    end
  end
end
```
Also instance should be created with token which will be used by middleware
```ruby
# ...
  def initialize(token:)
    save_config token: token
  end
# ...
```
Instantiate and use!
```ruby
client = RandomApiClient.new(token: 'Moms Birthday')
client.random_api_endpoint
client.random_api_endpoint_promise # yeap, asyncrony baby, backed by concurrent-ruby
client.same_with_dynamic_path(id: 1)
client.same_with_dynamic_path_promise(id: 1).then do |data_retrieved_through_pipes|
  # process it ...
end
```
