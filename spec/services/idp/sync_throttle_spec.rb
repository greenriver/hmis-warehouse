###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::SyncThrottle, type: :model do
  let(:user) { build_stubbed(:user, id: 42) }
  let(:someone_else) { build_stubbed(:user, id: 43) }

  before(:each) do
    # The test env nulls the cache out, so it would hold nothing.
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it 'grants the reservation to the first claim' do
    expect(described_class.claim!(user, pending: false)).to be_truthy
    expect(described_class).to be_held(user)
  end

  # The return value is the whole point — it decides whether this request does the read.
  it 'refuses a second claim while the first is held' do
    described_class.claim!(user, pending: false)

    expect(described_class.claim!(user, pending: false)).to be_falsey
  end

  it 'reserves per user, so one holder does not throttle anyone else' do
    described_class.claim!(user, pending: false)

    expect(described_class.claim!(someone_else, pending: false)).to be_truthy
  end

  it 'can be claimed again once released' do
    described_class.claim!(user, pending: false)
    described_class.release!(user)

    expect(described_class.claim!(user, pending: false)).to be_truthy
  end

  it 'holds for the full interval with no change in flight' do
    described_class.claim!(user, pending: false)

    travel(described_class::PENDING_INTERVAL + 1.second) do
      expect(described_class.claim!(user, pending: false)).to be_falsey
    end

    travel(described_class::INTERVAL + 1.minute) do
      expect(described_class.claim!(user, pending: false)).to be_truthy
    end
  end

  # A change the user started can land anywhere, so the read-back has to come round often enough to be
  # the mechanism rather than a backstop.
  it 'expires within the shorter interval while a change is in flight' do
    described_class.claim!(user, pending: true)

    travel(described_class::PENDING_INTERVAL + 1.second) do
      expect(described_class.claim!(user, pending: true)).to be_truthy
    end
  end
end
