require "spec_helper"

RSpec.describe Interloper do

  # Factory method for creating test classes that include Interloper by
  # default, and can be configured further with a block.
  def test_class_factory(parent_class: nil, &block)
    if parent_class
      Class.new(parent_class)
    else
      Class.new
    end.tap do |klass|
      klass.include Interloper
      klass.class_eval(&block) if block_given?
    end
  end

  describe 'test_class_factory' do
    let(:test_parent_class) do
      test_class_factory do
        def parent_method; end
      end
    end

    let(:test_child) { test_class_factory(parent_class: test_parent_class).new }

    it 'allows inheritance'  do
      expect(test_child).to be_a test_parent_class
      expect(test_child).to respond_to :parent_method
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

  describe 'subclasses and superclasses defining callbacks on the same method' do
    # Define an anonymous class on which we can make observable method calls
    # in our tests
    let(:observable) do
      Class.new do
        def observe(x); end
      end.new
    end

    # Define a parent class with before and after callbacks hooked onto a
    # method, which then makes additional method calls we can observe in tests.
    let(:test_parent_class) do
      test_class_factory do
        before(:do_something) do |observable|
          observable.observe("parent before doing something")
        end

        after(:do_something) do |observable|
          observable.observe("parent after doing something")
        end

        def do_something(observable)
          observable.observe("doing something")
        end
      end
    end

    # Define a child class with additional before and after callbacks.
    let(:test_child_class) do
      test_class_factory(parent_class: test_parent_class) do
        before(:do_something) do |observable|
          observable.observe("child before doing something")
        end

        after(:do_something) do |observable|
          observable.observe("child after doing something")
        end
      end
    end

    let(:test_parent) { test_parent_class.new }
    let(:test_child) { test_child_class.new }

    it 'subclasses have the "innermost" callbacks' do
      expect(observable).to receive(:observe).with("child before doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("parent before doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("parent after doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("child after doing something").exactly(1).times.ordered

      test_child.do_something(observable)
    end
  end
end
