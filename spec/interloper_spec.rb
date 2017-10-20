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

  let(:test_class) { test_class_factory }

  it "has a version number" do
    expect(Interloper::VERSION).not_to be nil
  end

  context 'when extended by a class' do
    subject { test_class }

    context 'provides a class interface:' do
      it { is_expected.to respond_to(:before) }
      it { is_expected.to respond_to(:after) }
    end

    context 'when a before hook is configured for a method' do

      let(:test_class) do
        test_class_factory do
          # Add callback to run before :do_something
          before(:do_something) { before_do_something }

          # Define the callback here so we can test to see if it's called.
          def before_do_something; end

          # Define the method we're adding callbacks for.
          def do_something
            # Call a method tha we can test to see if/when it's been called.
            observable_action
          end

          # Define a method that we can test to see it it's called.
          def observable_action; end
        end
      end

      let(:test_instance) { test_class.new }

      it 'calls the hook before the method is called' do
        expect(test_instance).to receive(:before_do_something).exactly(1).times.ordered
        expect(test_instance).to receive(:observable_action).exactly(1).times.ordered
        test_instance.do_something
      end
    end
  end
end
