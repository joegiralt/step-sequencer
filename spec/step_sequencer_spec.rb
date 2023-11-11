# frozen_string_literal: true

require 'spec_helper'

class DummyOrderClass
  include StepSequencer
  sequencer do
    step :pushes_1
    step :pushes_2
    step :pushes_3
    step :pushes_4

    on_halt do |step, reason|
      "#{step}: #{reason}"
    end
  end

  def pushes_1(list)
    list.push(1)
  end

  def pushes_2(list)
    list.push(2)
  end

  def pushes_3(list)
    list.push(3)
  end

  def pushes_4(list)
    list.push(4)
  end
end

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

class DummyNoOnHaltHandler
  include StepSequencer

  sequencer do
    step :some_step
  end

  def some_step
    halt_sequence!({ random_key: 'user defined halt reason passed to halt_sequence!' })
  end
end

class DummyMissingStep
  include StepSequencer

  sequencer do
    step :missing_method_step
    step :some_other_step
  end

  def some_other_step; end

  # missing step :p
  # def missing_method_step; end
end

RSpec.describe StepSequencer do
  # Dummy class for testing purposes
  let(:initial_value) { 5 }
  let(:order_instance) { DummyOrderClass.new }
  let(:arithmetic_instance) { DummyArithmeticClass.new }
  let(:no_arity_instance) { DummyNoArityClass.new(initial_value) }
  let(:halt_on_last_step_instance) { DummyHaltOnLastStep.new }
  let(:no_halt_handler_instance) { DummyNoOnHaltHandler.new }
  let(:missing_step_instance) { DummyMissingStep.new }

  describe '#start_sequence' do
    it 'executes the steps in the correct order' do
      result = order_instance.start_sequence([])

      expect(result).to eq([1, 2, 3, 4])
    end

    context 'when a step canexplicitly halt the sequence' do
      it 'stops the sequence at the specified step' do
        expect(arithmetic_instance.start_sequence(11)).to eq('halts_if_greater_than_ten: value is greater that 10')
      end

      it 'executes the entire sequence' do
        expect(arithmetic_instance.start_sequence(1)).to eq(6)
      end

      it 'stops the sequence at the specified step and its the last step' do
        expect(halt_on_last_step_instance.start_sequence).to eq(:halts_last_step)
      end

      it 'halts the sequence and measures halt status' do
        halt_on_last_step_instance.start_sequence
        expect(halt_on_last_step_instance.halted).to be(true)
      end

      it 'halts the sequence with the specified reason' do
        halt_on_last_step_instance.start_sequence
        expect(halt_on_last_step_instance.halted_reason).to eq({ error: 'some random error on final step' })
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

    it 'has the same value as the instance var store' do
      expect(no_arity_instance.start_sequence).to eq(no_arity_instance.value)
    end
  end

  context 'when theres no halt_handler configured' do
    it 'defaults to default halt_handler' do
      expect(no_halt_handler_instance.start_sequence).to eq({ some_step: { random_key: 'user defined halt reason passed to halt_sequence!' } })
    end
  end

  context 'when a step isnt configured' do
    it 'throws a NoMethodError Exception' do
      expect { missing_step_instance.start_sequence }.to raise_error(NoMethodError)
    end

    it 'throws a NoMethodError Exception with correct message' do
      expect { missing_step_instance.start_sequence }.to raise_error(NoMethodError, 'Method `missing_method_step` is not defined for DummyMissingStep used in steps')
    end
  end
end
