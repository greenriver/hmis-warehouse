# frozen_string_literal: true

require 'rails_helper'

# Test model that includes SimpleStateMachine
class SimpleStateMachineTestRecord < ActiveRecord::Base
  include SimpleStateMachine
  aasm column: 'status' do
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

RSpec.describe SimpleStateMachine do
  before(:all) do
    ActiveRecord::Base.connection.create_table :simple_state_machine_test_records, force: true do |t|
      t.string :status
      t.timestamps
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :simple_state_machine_test_records
  end

  let(:record) { SimpleStateMachineTestRecord.create! }

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
  end

  describe 'event transitions' do
    it 'transitions from open to locked' do
      expect do
        record.reserve!
      end.to change { record.status }.from('open').to('locked')
    end

    it 'transitions from locked to open' do
      record.reserve!
      expect do
        record.release!
      end.to change { record.status }.from('locked').to('open')
    end

    it 'transitions from open to closed' do
      expect do
        record.close!
      end.to change { record.status }.from('open').to('closed')
    end

    it 'transitions from locked to closed' do
      record.reserve!
      expect do
        record.close!
      end.to change { record.status }.from('locked').to('closed')
    end

    it 'returns false for invalid transitions' do
      record.close!
      expect(record.closed?).to be true
      expect(record.reserve!).to be false
      expect(record.release!).to be false
      expect(record.closed?).to be true
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
