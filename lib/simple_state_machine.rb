# replace unmaintained AASM
module SimpleStateMachine
  module ClassMethods
    def state_machine(column: 'state', &block)
      class_eval do
        extend SimpleStateMachine::StateDefinitions
        include SimpleStateMachine::InstanceMethods

        cattr_accessor :state_machine_column, :states, :events, :transitions

        self.state_machine_column = column
        self.states = {}
        self.events = {}
        self.transitions = {}

        class_eval(&block) if block_given?

        # Create predicate methods for states
        states.each do |state_name, options|
          define_method("#{state_name}?") do
            current_state == state_name.to_s
          end
        end

        # Create event methods
        events.each do |event_name, _|
          define_method(event_name) do |*args|
            run_event(event_name, *args)
          end

          define_method("may_#{event_name}?") do
            can_run_event?(event_name)
          end

          define_method("#{event_name}!") do |*args|
            run_event!(event_name, *args)
          end
        end

        # Set initial state for new records
        after_initialize do
          if new_record?
            initial_state = states.find { |_, options| options[:initial] }&.first
            write_attribute(state_machine_column, initial_state.to_s) if initial_state
          end
        end

        # Add validation
        validate do
          unless states.keys.map(&:to_s).include?(current_state)
            errors.add(state_machine_column, "is not a valid state")
          end
        end
      end
    end
    alias_method :aasm, :state_machine
  end

  module StateDefinitions
    def state(name, options = {})
      states[name] = options
    end

    def event(name, &block)
      events[name] = {}
      event_def = EventDefinition.new(name, self)
      event_def.instance_eval(&block) if block_given?
    end
  end

  class EventDefinition
    def initialize(name, klass)
      @name = name
      @klass = klass
    end

    def transitions(options = {})
      from = Array(options[:from]).map(&:to_s)
      to = options[:to].to_s

      from.each do |from_state|
        @klass.transitions[@name] ||= {}
        @klass.transitions[@name][from_state] = to
      end
    end
  end

  module InstanceMethods
    def current_state
      read_attribute(self.class.state_machine_column).to_s
    end

    def can_run_event?(event_name)
      transitions = self.class.transitions[event_name] || {}
      transitions.key?(current_state)
    end

    def run_event(event_name, *args)
      return false unless can_run_event?(event_name)

      # Get the target state
      to_state = self.class.transitions[event_name][current_state]

      # Run callbacks (you could add before/after callbacks here)

      # Update the state
      write_attribute(self.class.state_machine_column, to_state)
      save
    end

    def run_event!(event_name, *args)
      result = run_event(event_name, *args)
      raise "Event '#{event_name}' cannot transition from '#{current_state}'" unless result
      result
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end
end

# Usage:
# class YourModel < ActiveRecord::Base
#   include SimpleStateMachine
#
#   state_machine column: 'status' do
#     state :unavailable, initial: true
#     state :available
#
#     event :enable do
#       transitions from: :unavailable, to: :available
#     end
#   end
# end
