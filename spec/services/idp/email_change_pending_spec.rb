###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::EmailChangePending, type: :model do
  let(:user) { build_stubbed(:user, id: 42) }
  let(:someone_else) { build_stubbed(:user, id: 43) }

  before(:each) do
    # The test env nulls the cache out, so it would hold nothing.
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  it 'answers false until a change is marked' do
    expect(described_class).not_to be_pending(user)
  end

  it 'answers true for the user whose change it is, and nobody else' do
    described_class.mark!(user)

    expect(described_class).to be_pending(user)
    expect(described_class).not_to be_pending(someone_else)
  end

  it 'forgets the change once it has been cleared' do
    described_class.mark!(user)
    described_class.clear!(user)

    expect(described_class).not_to be_pending(user)
  end

  # An abandoned change would otherwise keep the user on the accelerated read-back forever.
  it 'expires on its own' do
    described_class.mark!(user)

    travel(described_class::TTL + 1.minute) do
      expect(described_class).not_to be_pending(user)
    end
  end
end
