# StepSequencer Gem

StepSequencer is a Ruby gem providing a lightweight, intuitive DSL for defining and orchestrating a sequence of operations, also known as a workflow. Inspired by the functionality of musical sequencers, StepSequencer allows developers to chain together a series of steps that are executed in order, with the capability to halt the sequence based on custom conditions. This gem is particularly useful for scenarios where a set of tasks must be performed in a specific sequence, and where each task might depend on the outcome of the previous one.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'step-sequencer'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install step-sequencer
```

## Usage

To integrate StepSequencer into your Ruby application, you will need to require the gem and then create sequences. Here's how it could look:

```ruby
class DummyArithmeticService
  include StepSequencer

  sequencer do
    step :adds_five
    step :multiplies_by_random_number_from_external_client
    step :subtracts_three

    on_halt do |step, reason|
      "#{step}: #{reason}"
    end
  end

  def adds_five(num)
    num + 5
  end

  def subtracts_three(num)
    num - 3
  end

  def multiplies_random_number_from_external_client(num)
    result = SomeClient.new.get_random_number * num
    
    halt_sequence("result from client isn't a number") unless result.is_a?(Numeric)

    result
  end
end

# Usage
# happy path
DummyArithmeticService.new.start_sequence(100)
=> 734676 # some number

# Unhappy path
DummyArithmeticService.new.start_sequence(100)
=> "multiplies_by_random_number_from_external_client: result from client isn't a number"
```

It'll also catch errors on any step.

```ruby
class SomeService
  include StepSequencer

  sequencer do
    step :some_faulty_step
    step :other_step

    on_halt do |step, reason|
      "#{step}: #{reason}"
    end
  end

  def some_faulty_step(value)
    raise StandardError
  end
end

SomeService.new.start_sequence(:hi)
=> "some_faulty_step: StandardError"
```


## Features

- Intuitive DSL for defining sequences.
- Execute steps in a controlled order.
- Conditional execution of steps based on custom logic.
- Easy to integrate with existing Ruby applications.

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to be excellent to each other.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
