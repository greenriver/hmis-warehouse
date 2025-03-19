# frozen_string_literal: true

# SimpleStateMachine module provides a lightweight alternative to the AASM gem
module SimpleStateMachine
  # Extends the including class with class methods
  def self.included(base)
    base.extend(ClassMethods)
    base.class_attribute :aasm_column, :aasm_states, :aasm_events, :aasm_initial_state, instance_accessor: false
  end

  # Class methods added to the including class
  module ClassMethods
    # Sets up the state machine configuration
    # @param column [Symbol] the database column that stores the state
    def aasm(column: :state, &block)
      # Raise an exception if the aasm block has already been defined
      raise 'AASM block has already been defined for this class' if aasm_column || aasm_states || aasm_events

      self.aasm_column = column
      self.aasm_states = {}
      self.aasm_events = {}

      # Execute the configuration block in a DSL context
      AasmDSL.new(self).instance_eval(&block) if block

      # Define state query methods
      aasm_states.each_key do |state_name|
        define_method("#{state_name}?") { self[aasm_column] == state_name.to_s }

        # Class-level scope
        scope state_name, -> { where(aasm_column => state_name.to_s) }
      end

      # Define event methods
      aasm_events.each do |event_name, transition_map|
        # Define bang method that performs the transition
        define_method("#{event_name}!") do
          current_state = self[aasm_column]&.to_s

          # Find a valid transition
          transition_to = transition_map[current_state]
          return false unless transition_to

          self[aasm_column] = transition_to
          save!
          true
        end

        # Define predicate method for checking if transition is possible
        define_method("may_#{event_name}?") do
          current_state = self[aasm_column]&.to_s
          transition_map.key?(current_state)
        end
      end

      # Set initial state for new records
      after_initialize :set_initial_state, if: :new_record?
    end

    def aasm_state_names
      aasm_states.keys
    end
  end

  # DSL for AASM configuration
  class AasmDSL
    def initialize(klass)
      @klass = klass
    end

    # Defines a state
    # @param name [Symbol] the name of the state
    # @param initial [Boolean] whether this is the initial state
    def state(name, initial: false)
      @klass.aasm_states[name] = { initial: initial }
      @klass.aasm_initial_state = name if initial
    end

    # Defines an event
    # @param name [Symbol] the name of the event
    # @param &block [Block] the configuration block for the event
    def event(name, &block)
      event_dsl = EventDSL.new
      event_dsl.instance_eval(&block)
      @klass.aasm_events[name] = event_dsl.transition_map
    end
  end

  # DSL for configuring events
  class EventDSL
    attr_reader :transition_map

    def initialize
      @transition_map = {}
    end

    # Defines a transition
    # @param from [Symbol, Array<Symbol>] state(s) from which the transition is valid
    # @param to [Symbol] state to which the transition goes
    # @raise [ArgumentError] if ambiguous transitions are defined
    def transitions(from:, to:)
      Array(from).each do |state|
        state = state.to_s
        raise ArgumentError, "Ambiguous transition defined: '#{state}' has multiple possible transitions in the same event" if @transition_map.key?(state)

        @transition_map[state] = to.to_s
      end
    end
  end

  # instance methods
  def aasm_column
    self.class.aasm_column
  end

  private

  # Sets the initial state for new records
  def set_initial_state
    return unless self.class.aasm_initial_state

    self[self.class.aasm_column] ||= self.class.aasm_initial_state.to_s
  end
end
