require "spec_helper"

RSpec.describe Interloper do

  # Factory method for creating test classes that include Interloper by
  # default, and can be configured further with a block.
  def test_class_factory(&block)
    Class.new do
      include Interloper
    end.tap do |klass|
      klass.class_eval(&block) if block_given?
    end
  end

  # Default helpers
  let(:test_class) { test_class_factory }
  let(:test_instance) { test_class.new }

  it "has a version number" do
    expect(Interloper::VERSION).not_to be nil
  end

  describe 'provides .before and .after class methods' do
    subject { test_class }
    it { is_expected.to respond_to(:before) }
    it { is_expected.to respond_to(:after) }
  end


  context 'when before and after callbacks are set' do
    let(:test_class) do
      test_class_factory do
        before(:do_something) { do_something_before }
        before(:do_something) { then_do_something_else_before }
        after(:do_something) { do_something_after }
        after(:do_something) { then_do_something_else_after }

        def do_something_before; end
        def then_do_something_else_before; end
        def do_something
          observable_action
        end
        def observable_action; end
        def do_something_after; end
        def then_do_something_else_after; end
      end
    end

    it 'runs callbacks in the proper order' do
      expect(test_instance).to receive(:do_something_before).exactly(1).times.ordered
      expect(test_instance).to receive(:then_do_something_else_before).exactly(1).times.ordered
      expect(test_instance).to receive(:observable_action).exactly(1).times.ordered
      expect(test_instance).to receive(:do_something_after).exactly(1).times.ordered
      expect(test_instance).to receive(:then_do_something_else_after).exactly(1).times.ordered
      test_instance.do_something
    end
  end

  describe 'callbacks that receive arguments' do
    let(:test_class) do
      test_class_factory do
        # Change the param within the callback and then test the result.
        before(:do_something) do |test_hash|
          test_hash[:value] += 1
        end
        def do_something(x); end
      end
    end

    let(:test_hash) { { value: 0 } }

    it 'receives the same arguments as the method it is interloping' do
      expect { test_instance.do_something(test_hash) }.to change { test_hash[:value] }.from(0).to(1)
    end
  end
end
