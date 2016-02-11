require 'simplecov'

module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV['COVERAGE'] && SimpleCov.start do
  add_filter '/.rvm/'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'bundler'
Bundler.require(:default, :test)
require 'clientura'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.order = :rand

  config.before(:suite) do
    pid = Process.fork do
      trap(:INT) { Rack::Handler::WEBrick.shutdown }
      Rack::Handler::WEBrick.run TestServer.new, Port: 3001
      exit
    end

    at_exit do
      Process.kill('INT', pid)
      begin
        Process.wait(pid)
      rescue Errno::ECHILD
        # ignore this error...I think it means the child process has already exited.
      end
    end

    sleep 1
  end
end
