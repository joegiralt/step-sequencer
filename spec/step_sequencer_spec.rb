require 'spec_helper'

RSpec.describe StepSequencer do
  # Dummy class for testing purposes
  class DummyArithmeticClass
    include StepSequencer

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

  class DummyNoArityClass
    include StepSequencer

    sequencer do
      step :adds_five_to_value
      step :adds_ten_to_value
      on_halt do |step, reason|
        "#{step}: #{reason}"
      end
    end

    attr_accessor :value

    def initialize(value)
      @value = value
    end

    def initialize(value)
      @value = value
    end

    def adds_five_to_value
      @value += 5
      @value
    end

    def adds_ten_to_value
      @value += 10
      @value
    end
  end

  class DummyHaltOnLastStep
    include StepSequencer

    sequencer do
      step :foo
      step :halts_last_step
      on_halt do |step, _reason|
        step
      end
    end

    def foo; end

    def halts_last_step
      halt_sequence!({ error: 'some random error on final step' })
    end
  end

  let(:initial_value) { 5 }
  let(:arithmetic_instance) { DummyArithmeticClass.new }
  let(:no_arity_instance) { DummyNoArityClass.new(initial_value) }
  let(:halt_on_last_step_instance) { DummyHaltOnLastStep.new }

  describe '#start_sequence' do
    it 'executes the steps in the correct order' do
      result = arithmetic_instance.start_sequence(initial_value)

      expect(result).to eq(14)
    end

    context 'when a step expliicitly halts the sequence' do
      it 'stops the sequence at the specified step' do
        expect(arithmetic_instance.start_sequence(11)).to eq('halts_if_greater_than_ten: value is greater that 10')
      end

      it 'stops the sequence at the specified step and its the last step' do
        expect(halt_on_last_step_instance.start_sequence).to eq(:halts_last_step)
      end
    end

    context 'when a step throws an error' do
      before do
        allow(arithmetic_instance).to receive(:subtract_three).and_throw(:foo)
      end

      it 'stops the sequence at the specified step' do
        expect(arithmetic_instance.start_sequence(initial_value)).to eq('halts_if_greater_than_ten: uncaught throw :foo')
      end
    end
  end

  context 'when a steps have an arity of 0' do
    it 'plays entire sequence of steps' do
      no_arity_instance
      expect(no_arity_instance.start_sequence).to eq(20)
    end
  end
end
