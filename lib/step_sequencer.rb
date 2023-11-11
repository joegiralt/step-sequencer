# frozen_string_literal: true

module StepSequencer
  class NoHaltHandlerConfigured < StandardError; end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_reader :steps, :halt_handler

    def sequencer(&block)
      @steps = []
      @halt_handler = proc do |step, reason|
        puts "No halt handler configured for #{self.class.name}"
        { step => reason }
      end
      instance_eval(&block)
    end

    def step(name)
      @steps << name
    end

    def on_halt(&block)
      @halt_handler = block
    end
  end

  attr_accessor :halted, :halted_step, :halted_reason

  def halt_sequence!(reason)
    @halted        = true
    @halted_reason = reason
  end

  def start_sequence(initial_value = nil)
    accumulator = initial_value
    steps_list = [*self.class.steps, :terminus_of_sequence]
    steps_list.each_with_index do |step_name, idx|
      if @halted
        @halted_step = steps_list[idx - 1] # The step before the current one is the one that caused the halt
        # Yield to the on_halt block with the step and reason
        return self.class.halt_handler.call(@halted_step, @halted_reason)

      end
      next if step_name == :terminus_of_sequence

      # Verify if the step method exists
      unless respond_to?(step_name)
        raise NoMethodError, "Method `#{step_name}` is not defined for #{self.class.name} used in steps"
      end

      step_method = method(step_name)
      accumulator = step_method.arity.zero? ? step_method.call : step_method.call(accumulator)
    rescue NoMethodError => e
      raise # Re-raise NoMethodError to avoid catching it with StandardError
    rescue StandardError => e
      halt_sequence!(e.message) # Call halt_sequence! with the exception message
      retry # Restart the loop to handle the halt
    end

    accumulator
  end
end
