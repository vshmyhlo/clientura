require 'clientura/version'
require 'clientura/client'
require 'clientura/raising_promise'

module Clientura
  class << self
    def zip(*promises, &block)
      RaisingPromise
        .new(Concurrent::Promise.zip(*promises))
        .then(&block)
        .value
    end
  end
end
