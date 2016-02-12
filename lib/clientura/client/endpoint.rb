module Clientura
  module Client
    Endpoint = Struct.new(:verb, :path, :middleware, :pipes)
  end
end
