source 'http://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.

gem 'http', '~> 1.0'
gem 'concurrent-ruby', '~> 1.0', require: 'concurrent'
gem 'concurrent-ruby-edge', '~> 0.2', require: 'concurrent-edge'
gem 'concurrent-ruby-ext', '~> 1.0'
gem 'activesupport', '>= 4.0', require: [
  'active_support/core_ext/object',
  'active_support/json'
]

group :development, :test do
  gem 'rspec'
  gem 'rdoc'
  gem 'bundler'
  gem 'jeweler'
  gem 'simplecov'
  gem 'rubocop'
  gem 'pry'

  gem 'sinatra'
  gem 'sinatra-contrib'
  gem 'rack', require: [
    'rack',
    'rack/handler/webrick'
  ]
end
