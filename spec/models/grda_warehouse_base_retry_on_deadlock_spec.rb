###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GrdaWarehouseBase.retry_on_deadlock', type: :model do
  let(:calls) { [] }

  before do
    allow(GrdaWarehouseBase).to receive(:sleep)
    # The fixture transaction is always open; simulate autocommit mode.
    allow(GrdaWarehouseBase.connection).to receive(:transaction_open?).and_return(false)
  end

  it 'retries after a deadlock and returns the block result' do
    result = GrdaWarehouseBase.retry_on_deadlock('test') do
      calls << 1
      raise ActiveRecord::Deadlocked if calls.size == 1

      :ok
    end

    expect(result).to eq(:ok)
    expect(calls.size).to eq(2)
  end

  it 're-raises after exhausting attempts' do
    expect do
      GrdaWarehouseBase.retry_on_deadlock('test', attempts: 3) do
        calls << 1
        raise ActiveRecord::Deadlocked
      end
    end.to raise_error(ActiveRecord::Deadlocked)

    expect(calls.size).to eq(3)
  end

  # SerializationFailure shares Deadlocked's parent (TransactionRollbackError), so a widened rescue would catch it
  it 'does not retry other database errors' do
    expect do
      GrdaWarehouseBase.retry_on_deadlock('test') do
        calls << 1
        raise ActiveRecord::SerializationFailure
      end
    end.to raise_error(ActiveRecord::SerializationFailure)

    expect(calls.size).to eq(1)
  end

  it 'does not retry inside an open transaction' do
    allow(GrdaWarehouseBase.connection).to receive(:transaction_open?).and_return(true)

    expect do
      GrdaWarehouseBase.retry_on_deadlock('test') do
        calls << 1
        raise ActiveRecord::Deadlocked
      end
    end.to raise_error(ActiveRecord::Deadlocked)

    expect(calls.size).to eq(1)
  end
end
