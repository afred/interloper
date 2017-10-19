require "spec_helper"

RSpec.describe Interloper do
  it "has a version number" do
    expect(Interloper::VERSION).not_to be nil
  end

  context 'when extended by a class' do
    before :all do
      class TestClass
        extend Interloper
      end
    end

    context 'provides a class interface:' do
      subject { TestClass }
      it { is_expected.to respond_to(:before) }
      it { is_expected.to respond_to(:after) }
    end
  end


end
