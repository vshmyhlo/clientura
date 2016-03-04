# Clientura [![Build Status](https://travis-ci.org/v-shmyhlo/clientura.svg?branch=master)](https://travis-ci.org/v-shmyhlo/clientura) [![Test Coverage](https://codeclimate.com/github/v-shmyhlo/clientura/badges/coverage.svg)](https://codeclimate.com/github/v-shmyhlo/clientura/coverage) [![Code Climate](https://codeclimate.com/github/v-shmyhlo/clientura/badges/gpa.svg)](https://codeclimate.com/github/v-shmyhlo/clientura) [![Issue Count](https://codeclimate.com/github/v-shmyhlo/clientura/badges/issue_count.svg)](https://codeclimate.com/github/v-shmyhlo/clientura)

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
      get :comments # implicit path 'comments'
      get :users, path: 'api/users' # explicit path
      get :user, path: -> (params) { "api/users/#{params[:id]}"} # dynamic path
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
client.comments
client.comments_promise # yeap, asyncrony baby, backed by concurrent-ruby
client.users_promise.value # just retrieve result from promise
client.user(id: 1)
client.user_promise(id: 1).then do |data_retrieved_through_pipes|
  # process it asyncronously ...
end
```

### See more in [spec/clientura/adequate_spec.rb](spec/clientura/adequate_spec.rb)
