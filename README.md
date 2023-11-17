[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/8CPt6Mv94pfXo9ZdEYMK6x/1brR2pChhaaUpETXcpVTR/tree/main.svg?style=svg&circle-token=4eb1234d7d4bc8fa1641fcdd02b41f82d0295986)](https://dl.circleci.com/status-badge/redirect/circleci/8CPt6Mv94pfXo9ZdEYMK6x/1brR2pChhaaUpETXcpVTR/tree/main)
[![codecov](https://codecov.io/gh/joegiralt/step-sequencer/graph/badge.svg?token=ps0Jnbsy5x)](https://codecov.io/gh/joegiralt/step-sequencer)
[![FOSSA Status](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fjoegiralt%2Fstep-sequencer.svg?type=shield&issueType=license)](https://app.fossa.com/projects/git%2Bgithub.com%2Fjoegiralt%2Fstep-sequencer?ref=badge_shield&issueType=license)
# StepSequencer

![Step Sequencer](img/step-sequencer.png)

StepSequencer is a Ruby gem providing a lightweight, intuitive DSL for defining and orchestrating a sequence of operations, also known as a workflow. Inspired by the functionality of musical sequencers, StepSequencer allows developers to chain together a series of steps that are executed in order, with the capability to halt the sequence based on custom conditions. This gem is particularly useful for scenarios where a set of tasks must be performed in a specific sequence, and where each task might depend on the outcome of the previous one.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'step-sequencer-work-flow'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install step-sequencer-work-flow
```
## Features

- Intuitive DSL for defining sequences.
- Execute steps in a controlled order.
- Sequences can be trivally be short circuited.
- Conditional execution of steps based on custom logic.
- Easy to integrate with existing Ruby applications.
- No need to wrap and unwrap the result like in other Monadic ruby gems.
- Zero dependencies.

## Usage

To integrate StepSequencer into your Ruby application, you will need to require the gem and then create sequences. Here's how it could look:

```ruby
require 'step_sequencer'

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
    
    halt_sequence!("result from client isn't a number") unless result.is_a?(Numeric)

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
require 'step_sequencer'

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
Here's what it could look like in a real application

```ruby
require 'step_sequencer'

class UserRegistration
  include StepSequencer

  attr_reader :user_data, :user

  def initialize(user_data)
    @user_data = user_data
  end

  sequencer do
    step :validates_input
    step :checks_user_exists
    step :sends_verification_email
    step :logs_registration
    on_halt do |step, reason|
      puts "Registration halted at '#{step}' due to: #{reason}"
      # Here the developer could define what to do when the sequence halts,
      # like cleaning up resources or alerting administrators.
      # or pass the data from that step to this handler via the `reason`.
    end
  end

  def start
    start_sequence(user_data)
  end

  private

  def validates_input(data)
    # Validate user input...
    halt_sequence!('Invalid input') unless data[:email].match?(/\A[^@\s]+@[^@\s]+\z/)
    data
  end

  def checks_user_exists(data)
    # Check if user exists...
    halt_sequence!('User already exists') if User.exists?(email: data[:email])
    data
  end

  def sends_verification_email(data)
    # Send email...
    UserMailer.verification_email(data[:email]).deliver_now
    data
  end

  def logs_registration(data)
    # Log registration...
    RegistrationLog.create!(user_data: data)
    data
  end
end

# Usage
user_data = { name: 'Jane Doe', email: 'jane.doe@example.com' }
registration = UserRegistration.new(user_data)
registration.start

```
Here's an example where it's doing very simple ETL
```ruby
require 'step_sequencer'
require 'http'
require 'json'

class DataPipeline
  include StepSequencer

  API_ENDPOINT = 'https://api.example.com/data'
  REPORT_PATH = '/path/to/reports'

  sequencer do
    step :fetches_data
    step :transforms_data
    step :saves_data
    step :generates_report
    step :sends_notification
    on_halt do |step, reason|
      puts "Data pipeline halted at '#{step}' due to: #{reason}"
      # Implement logging or notification logic here.
      # perhaps backtracking or data clean up bad data.
    end
  end

  def run
    start_sequence(nil) # Initial value is not used in this case.
  end

  private

  def fetches_data(_)
    response = HTTP.get(API_ENDPOINT)
    halt_sequence!('Failed to fetch data') unless response.status.success?
    JSON.parse(response.to_s)
  end

  def transforms_data(raw_data)
    # Perform data transformation...
    transformed_data = raw_data.map do |entry|
      # Transformation logic here.
    end
    halt_sequence!('Data transformation failed') if transformed_data.empty?
    transformed_data
  end

  def saves_data(transformed_data)
    # Save data to database...
    halt_sequence!('Failed to save data') unless Database.save(transformed_data)
    transformed_data
  end

  def generates_report(data)
    # Generate report from data...
    report = ReportGenerator.new(data)
    halt_sequence!('Report generation failed') unless report.generate(REPORT_PATH)
    report
  end

  def sends_notification(report)
    # Send notification email...
    NotificationMailer.report_ready(report).deliver_now
    report
  end
end

# Usage
data_pipeline = DataPipeline.new
data_pipeline.run

```
## Caveats

When using StepSequencer, it's important to understand how it handles methods with different numbers of arguments (referred to as "arity"). This can affect the behavior of your sequence in significant ways:

### Methods with Arity (Methods that Accept Arguments)
- Single Argument: If a method is defined to take a single argument, the StepSequencer will pass the result of the previous step to it. This allows for a chain of data transformation where each step receives the output of the last, and uses it to produce its own output.

```ruby
def step_method(accumulator)
  # The accumulator is the result from the previous step
  transformed_data = some_transformation(accumulator)
  transformed_data # This will be passed to the next step
end
```
- Multiple Arguments: If a method is defined to take multiple arguments, you must manually manage how it is called within the sequence. StepSequencer does not automatically handle methods that expect more than one argument.

### Methods Without Arity (Parameterless Methods)
- These methods do not accept any arguments and are called without passing the result of the previous step. They're useful for executing actions that don't need input from preceding steps, like logging or sending notifications. However, they won't automatically receive the accumulator from the previous step.
```ruby
def parameterless_step
  # Perform an action that does not depend on the previous step's output
  perform_independent_action
end
```
### Behavior in Sequences
- When defining a sequence, it is crucial to be aware of each method's arity to ensure they are used correctly within the sequence. If a method with arity is defined without providing the necessary arguments, or if a method without arity is expected to receive arguments, it may result in an error.

### Halting Sequences
- The halt_sequence! method is designed to halt the execution of a sequence. This method should be used within the steps where a condition might require the sequence to stop immediately. When halt_sequence! is invoked, it sets a flag that the sequence checks after each step. If the flag is set, the sequence stops, and the on_halt block is called with the reason for the halt.
- it is important to note that the halt_sequence! method does not take into account the arity of the steps. It simply stops the sequence regardless of the steps' design.

### Recommendations
- It is recommended to design your sequence steps with a consistent approach to argument passing. If a step's output is not relevant to the next step, consider restructuring your workflow or explicitly managing the flow of data between steps.

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to be excellent to each other.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
