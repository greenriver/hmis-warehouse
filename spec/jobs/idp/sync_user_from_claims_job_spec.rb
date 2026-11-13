###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::SyncUserFromClaimsJob, :jwt_only, type: :job do
  let!(:user) { create(:user, email: 'before@example.com', first_name: 'Self', last_name: 'Serve') }

  def claims(overrides = {})
    { email: 'after@example.com', email_verified: true, first_name: 'Ada', last_name: 'Lovelace' }.merge(overrides)
  end

  it 'adopts the claimed profile' do
    described_class.new.perform(user_id: user.id, claims: claims)

    expect(user.reload.email).to eq('after@example.com')
    expect(user.first_name).to eq('Ada')
  end

  it 'builds no IdP service' do
    expect(Idp::ServiceFactory).not_to receive(:for_connector)

    described_class.new.perform(user_id: user.id, claims: claims)
  end

  it 're-points HMIS HUD user rows from the previous address' do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

    described_class.new.perform(user_id: user.id, claims: claims)
  end

  it 're-points HMIS HUD user rows for a name-only change' do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).to receive(:sync_to_hud_users).with(previous_email: nil)

    described_class.new.perform(user_id: user.id, claims: claims(email: 'before@example.com'))
  end

  it 'does not re-point HMIS rows when nothing moved' do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).not_to receive(:sync_to_hud_users)

    described_class.new.perform(user_id: user.id, claims: claims(email: 'before@example.com', first_name: 'Self', last_name: 'Serve'))
  end

  it 'refuses an address the IdP reports as unconfirmed' do
    described_class.new.perform(user_id: user.id, claims: claims(email_verified: false))

    expect(user.reload.email).to eq('before@example.com')
  end

  it 'adopts an address when the IdP is silent on verification (nil claim)' do
    described_class.new.perform(user_id: user.id, claims: claims(email_verified: nil))

    expect(user.reload.email).to eq('after@example.com')
  end

  it 'rolls the adopted profile back when the HMIS re-point fails' do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    allow(user).to receive(:sync_to_hud_users).and_raise(ActiveRecord::RecordInvalid.new(user))
    allow(Sentry).to receive(:capture_exception_with_info)

    described_class.new.perform(user_id: user.id, claims: claims)

    expect(user.reload.email).to eq('before@example.com')
  end

  it 'reports an address another user already holds rather than raising' do
    create(:user, email: 'after@example.com')
    expect(Sentry).to receive(:capture_exception_with_info).with(
      kind_of(ActiveRecord::RecordInvalid),
      /Couldn't adopt IdP profile claims for user #{user.id}/,
      hash_including(user_id: user.id),
    )

    expect { described_class.new.perform(user_id: user.id, claims: claims) }.not_to raise_error
    expect(user.reload.email).to eq('before@example.com')
  end

  it 'accepts claims with string keys' do
    described_class.new.perform(user_id: user.id, claims: claims.stringify_keys)

    expect(user.reload.email).to eq('after@example.com')
  end

  it 'tolerates a user deleted between enqueue and run' do
    expect { described_class.new.perform(user_id: user.id + 1_000, claims: claims) }.not_to raise_error
  end
end
