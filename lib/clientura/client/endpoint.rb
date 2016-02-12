module Clientura
  module Client
    Endpoint = Struct.new(:verb, :path, :headers, :middleware, :pipes)
  end
end
