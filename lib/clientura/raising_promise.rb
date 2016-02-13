module Clientura
  class RaisingPromise < SimpleDelegator
    class << self
      def zip(*promises)
        new Concurrent::Promise.zip(*promises)
      end
    end

    def initialize(source = nil, &block)
      super source.present? ? source : Concurrent::Promise.new(&block)
    end

    [:execute, :then, :on_success].each do |m|
      define_method m do |*args, &block|
        RaisingPromise.new super(*args, &block)
      end
    end

    def value(*args, &block)
      res = super(*args, &block)
      raise reason if rejected?
      res
    end
  end
end
