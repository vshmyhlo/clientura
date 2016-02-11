# require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Clientura do
  describe Clientura::VERSION do
    subject { described_class }

    it { should_not be_blank }
  end
end
