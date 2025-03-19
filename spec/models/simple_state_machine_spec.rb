# frozen_string_literal: true

require 'rails_helper'

# Test models that include SimpleStateMachine
class SimpleStateMachineTestRecord < ActiveRecord::Base
  include SimpleStateMachine
  state_machine_config column: 'status' do
    state :open, initial: true
    state :locked
    state :closed

    event :close do
      transitions from: [:open, :locked], to: :closed
    end

    event :reserve do
      transitions from: :open, to: :locked
    end

    event :release do
      transitions from: :locked, to: :open
    end
  end
end

# Minimal test models for specific tests
class CustomColumnStateMachineRecord < ActiveRecord::Base
  include SimpleStateMachine
  state_machine_config column: 'workflow_state' do
    state :draft, initial: true
    state :review
    event :submit do
      transitions from: :draft, to: :review
    end
  end
end

class AmbiguousStateMachineRecord < ActiveRecord::Base
  include SimpleStateMachine
end

RSpec.describe SimpleStateMachine do
  before(:all) do
    # Create tables for all test models
    tables = {
      simple_state_machine_test_records: { column: :status },
      custom_column_state_machine_records: { column: :workflow_state },
      ambiguous_state_machine_records: { column: :state },
    }

    tables.each do |table_name, options|
      ActiveRecord::Base.connection.create_table table_name, force: true do |t|
        t.string options[:column]
        t.timestamps
      end
    end
  end

  after(:all) do
    # Drop all test tables
    [
      :simple_state_machine_test_records,
      :custom_column_state_machine_records,
      :ambiguous_state_machine_records,
    ].each do |table_name|
      ActiveRecord::Base.connection.drop_table table_name
    end
  end

  let(:record) { SimpleStateMachineTestRecord.create! }
  let(:custom_record) { CustomColumnStateMachineRecord.create! }

  describe 'initialization' do
    it 'raises an error when state machine is redefined' do
      expect do
        Class.new(ActiveRecord::Base) do
          include SimpleStateMachine
          state_machine_config do
            state :one, initial: true
          end

          state_machine_config do
            state :two, initial: true
          end
        end
      end.to raise_error(RuntimeError, /block has already been defined for this class/)
    end

    it 'supports custom column names' do
      expect(custom_record.workflow_state).to eq('draft')
    end
  end

  describe 'state definitions' do
    it 'sets the initial state' do
      expect(record.status).to eq('open')
      expect(record.open?).to be true
    end

    it 'defines state query methods' do
      expect(record).to respond_to(:open?)
      expect(record).to respond_to(:locked?)
      expect(record).to respond_to(:closed?)
    end

    it 'scopes return correct records' do
      klass = SimpleStateMachineTestRecord
      open_record = klass.create!
      locked_record = klass.create!
      locked_record.reserve!
      closed_record = klass.create!
      closed_record.close!

      expect(klass.open.to_a).to include(open_record)
      expect(klass.open.to_a).not_to include(locked_record, closed_record)

      expect(klass.locked.to_a).to include(locked_record)
      expect(klass.locked.to_a).not_to include(open_record, closed_record)

      expect(klass.closed.to_a).to include(closed_record)
      expect(klass.closed.to_a).not_to include(open_record, locked_record)
    end
  end

  describe 'ambiguous transitions' do
    it 'raises an error when the same state appears in multiple transitions' do
      expect do
        Class.new(AmbiguousStateMachineRecord) do
          state_machine_config do
            state :initial, initial: true
            state :final

            event :ambiguous do
              transitions from: :initial, to: :final
              transitions from: :initial, to: :initial # Should raise error
            end
          end
        end
      end.to raise_error(ArgumentError, /Ambiguous transition defined/)
    end
  end

  describe 'event transitions' do
    it 'transitions between states correctly' do
      # Test open -> locked transition
      expect { record.reserve! }.to change { record.status }.from('open').to('locked')

      # Test locked -> open transition
      expect { record.release! }.to change { record.status }.from('locked').to('open')

      # Test open -> closed transition
      record = SimpleStateMachineTestRecord.create!
      expect { record.close! }.to change { record.status }.from('open').to('closed')

      # Test locked -> closed transition
      record = SimpleStateMachineTestRecord.create!
      record.reserve!
      expect { record.close! }.to change { record.status }.from('locked').to('closed')
    end

    it 'returns false for invalid transitions' do
      record.close!
      expect(record.closed?).to be true
      expect(record.reserve!).to be false
      expect(record.release!).to be false
    end

    it 'handles multiple from states and persists changes' do
      # Test multiple from states
      open_record = SimpleStateMachineTestRecord.create!
      locked_record = SimpleStateMachineTestRecord.create!
      locked_record.reserve!

      expect(open_record.close!).to be true
      expect(locked_record.close!).to be true

      # Test persistence
      reloaded = SimpleStateMachineTestRecord.find(locked_record.id)
      expect(reloaded.status).to eq('closed')
    end
  end

  describe 'may_* predicate methods' do
    it 'returns true when transition is allowed' do
      expect(record.may_close?).to be true
      expect(record.may_reserve?).to be true
      expect(record.may_release?).to be false
    end

    it 'returns false when transition is not allowed' do
      record.close!
      expect(record.may_close?).to be false
      expect(record.may_reserve?).to be false
      expect(record.may_release?).to be false
    end
  end
end
