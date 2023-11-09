require 'spec_helper'

RSpec.describe StepSequencer do
  # Dummy class for testing purposes
  class DummyClass
    include StepSequencer

    attr_accessor :value

    def initialize(value)
      @value = value
    end

    sequencer do
      step :add_five
      step :subtract_three
      step :multiply_by_two

      on_halt do |reason|
        reason
      end
    end

    def add_five(num)
      num + 5
    end

    def subtract_three(num)
      num - 3
    end

    def multiply_by_two(num)
      num * 2
    end
  end

  let(:initial_value) { 10 }
  let(:dummy_instance) { DummyClass.new(initial_value) }

  describe '#start_sequence' do
    it 'executes the steps in the correct order' do
      result = dummy_instance.start_sequence(initial_value)
      # The expected result after sequence: ((10 + 5) - 3) * 2
      expect(result).to eq(24)
    end

    context 'when a step halts the sequence' do
      before do
        allow(dummy_instance).to receive(:subtract_three).and_throw(:foo)
      end

      it 'stops the sequence at the specified step' do
        expect(dummy_instance.start_sequence(initial_value)).to eq('uncaught throw :foo')
      end
    end
  end
end

# class DummyClass
#   include StepSequencer

#   sequencer do
#     step :add_five
#     step :subtract_three
#     step :multiply_by_two

#     on_halt do |reason|
#       puts reason
#       :test_halt
#     end
#   end

#   def initialize
#     # nothing here
#   end

#   def add_five(num)
#     value + 5
#   end

#   def subtract_three(num)
#     value - 3
#   end

#   def multiply_by_two(num)
#     value * 2
#   end
# end

# # When called
# DummyClass.new.start_sequence(10)
# => 24

# # if subtract_three throws an error for some reason
# DummyClass.new.start_sequence(10)
# => :test_halt
