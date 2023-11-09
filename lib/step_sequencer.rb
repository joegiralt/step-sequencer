# module StepSequencer
#   def self.included(base)
#     base.extend ClassMethods
#   end

#   module ClassMethods
#     attr_accessor :steps, :halt_handler

#     def sequencer(&block)
#       @steps = []
#       @halt_handler = proc { |step, reason| puts "Halting at '#{step}': #{reason}" }
#       instance_exec(&block)
#     end

#     def step(name, &block)
#       @steps << { name: name, callable: block }
#     end

#     def on_halt(&block)
#       @halt_handler = block
#     end

#     def run_steps(context, initial_value)
#       accumulator = initial_value

#       @steps.each do |step|
#         begin
#           method = context.method(step[:callable] || step[:name])

#           accumulator = method.arity.zero? ? method.call : method.call(accumulator)
#         rescue => e
#           return context.halt_sequence!(step[:name], e.message)
#           # return nil
#         end
#         binding.pry
#         # Check after each step if halt has been triggered
#         if context.halted
#           @halt_handler.call(context.halted_step, context.halted_reason)
#           # return nil
#         end
#       end

#       accumulator
#     end
#   end

#   attr_accessor :halted, :halted_step, :halted_reason, :initial_value

#   def initialize(initial_value = 0, *args)
#     @initial_value = initial_value
#     @halted = false
#     super(*args) # If you use super, ensure the parent class can handle it.
#   end

#   def halt_sequence!(step_name, reason)
#     @halted = true
#     @halted_step = step_name
#     @halted_reason = reason
#     throw :halt_sequence
#   end

#   def start_sequence(initial_value)
#     catch :halt_sequence do
#       self.class.run_steps(self, initial_value)
#     end
#   end
# end

module StepSequencer
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    attr_reader :steps, :halt_handler

    def sequencer(&block)
      @steps = []
      @halt_handler = proc { |reason| puts "Halting sequence: #{reason}" }
      instance_eval(&block)
    end

    def step(name)
      @steps << name
    end

    def on_halt(&block)
      @halt_handler = block
    end
  end

  def start_sequence(initial_value)
    accumulator = initial_value
    halt_result = nil

    self.class.steps.each do |step_name|
      accumulator = send(step_name, accumulator)
    rescue StandardError => e
      halt_result = self.class.halt_handler.call(e.message) if self.class.halt_handler
      return halt_result || :halted
    end

    accumulator
  end
end
