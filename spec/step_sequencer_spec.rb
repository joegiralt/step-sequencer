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
      step :halts_if_greater_than_ten
      step :subtract_three
      step :multiply_by_two

      on_halt do |step, reason|
        "#{step}: #{reason}"
      end
    end

    def add_five(num)
      num + 5
    end

    def halts_if_greater_than_ten(num)
      halt_sequence!('value is greater that 10') if num > 10

      num
    end

    def subtract_three(num)
      num - 3
    end

    def multiply_by_two(num)
      num * 2
    end
  end

  let(:initial_value) { 2 }
  let(:dummy_instance) { DummyClass.new(initial_value) }

  describe '#start_sequence' do
    it 'executes the steps in the correct order' do
      result = dummy_instance.start_sequence(initial_value)
      # The expected result after sequence: ((10 + 5) - 3) * 2
      expect(result).to eq(8)
    end

    context 'when a step expliicitly halts teh sequence' do
      it 'stops the sequence at the specified step' do
        expect(dummy_instance.start_sequence(11)).to eq('halts_if_greater_than_ten: value is greater that 10')
      end
    end

    context 'when a step throws an error' do
      before do
        allow(dummy_instance).to receive(:subtract_three).and_throw(:foo)
      end

      it 'stops the sequence at the specified step' do
        expect(dummy_instance.start_sequence(initial_value)).to eq('halts_if_greater_than_ten: uncaught throw :foo')
      end
    end
  end
end
