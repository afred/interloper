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

  # Define an test double that we can call methods on and set expectations.
  let(:observable) do
    Class.new do
      def observe(x); end
    end.new
  end

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
        before(:do_something) { |observable| observable.observe("before do something") }
        before(:do_something) { |observable| observable.observe("before do something else") }
        after(:do_something) { |observable| observable.observe("after do something") }
        after(:do_something) { |observable| observable.observe("after do something else") }

        def do_something(observable)
          observable.observe("doing something")
          'foo'
        end
      end
    end

    it 'runs callbacks in the proper order' do
      expect(observable).to receive(:observe).with("before do something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("before do something else").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("after do something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("after do something else").exactly(1).times.ordered
      test_instance.do_something(observable)
    end

    it 'does not affect the return value of the method' do
      expect(test_instance.do_something(observable)).to eq 'foo'
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
    # Define a parent class with before and after callbacks hooked onto a
    # method, which then makes additional method calls we can observe in tests.
    let(:test_parent_class) do
      test_class_factory do
        before(:do_something) do |observable|
          observable.observe("parent before do something")
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
          observable.observe("child before do something")
        end

        after(:do_something) do |observable|
          observable.observe("child after doing something")
        end
      end
    end

    let(:test_parent) { test_parent_class.new }
    let(:test_child) { test_child_class.new }

    it 'subclasses have the "outermost" callbacks' do
      expect(observable).to receive(:observe).with("child before do something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("parent before do something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("parent after doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("child after doing something").exactly(1).times.ordered
      test_child.do_something(observable)
    end
  end

  describe '.inherit_callbacks_for' do
    let(:test_class) { test_class_factory }
    it 'calls .inherit_callbacks_before and .inherity_callbacks_after' do
      method_names = [:foo, :bar]
      expect(test_class).to receive(:inherit_callbacks_before).with(method_names).exactly(1).times
      expect(test_class).to receive(:inherit_callbacks_after).with(method_names).exactly(1).times
      test_class.inherit_callbacks_for(method_names)
    end
  end

  describe '.inherit_callbacks_before and .inherit_callbacks_after' do
    # Define a parent class with before and after callbacks hooked onto a
    # method, which then makes additional method calls we can observe in tests.
    let(:test_parent_class) do
      test_class_factory do
        before(:do_something) do |observable|
          observable.observe("parent before do something")
        end

        after(:do_something) do |observable|
          observable.observe("parent after doing something")
        end

        # No op; override in child class
        def do_something(observable)
          observable.observe("parent doing something")
        end
      end
    end

    let(:test_parent) { test_parent_class.new }
    let(:test_child) { test_child_class.new }

    # Define a child class that overrides the parent method, but inherits it's callbacks
    let(:test_child_class) do
      test_class_factory(parent_class: test_parent_class) do
        inherit_callbacks_before(:do_something)
        inherit_callbacks_after(:do_something)
        def do_something(observable)
          observable.observe("child doing something")
        end
      end
    end

    it 'allows a child class to inherit callback defined in a parent class' do
      expect(observable).to receive(:observe).with("parent before do something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("child doing something").exactly(1).times.ordered
      expect(observable).to receive(:observe).with("parent after doing something").exactly(1).times.ordered
      test_child.do_something(observable)
    end

    context 'where an overridden method calls super' do
      before do
        # Redefine test_child_class#do_something to call super.
        test_child_class.class_eval do |klass|
          def do_something(observable)
            observable.observe("child doing something")
            super
          end
        end
      end

      it "will call inherited callbacks around the child's method, and the parent's callbacks around the call to super" do
        expect(observable).to receive(:observe).with("parent before do something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("child doing something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("parent before do something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("parent doing something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("parent after doing something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("parent after doing something").exactly(1).times.ordered
        test_child.do_something(observable)
      end
    end

    context 'using named classes (instead of anonymous), subclasses overriding parent callbacks and not calling super' do

      before do
        class Parent
          include Interloper
          before(:do_something) { |observable| observable.observe("parent before do something") }
          def do_something(observable)
            observable.observe("parent doing something")
          end
        end

        class Child < Parent
          before(:do_something) { |observable| observable.observe("child before do something") }
          def do_something(observable)
            observable.observe("child doing something")
          end
        end
      end

      it "will only call the child's callbacks" do
        expect(observable).to receive(:observe).with("child before do something").exactly(1).times.ordered
        expect(observable).to receive(:observe).with("child doing something").exactly(1).times.ordered
        expect(observable).to_not receive(:observe).with("before parent do something")
        expect(observable).to_not receive(:observe).with("parent doing something")
        Child.new.do_something(observable)
      end
    end
  end
end
