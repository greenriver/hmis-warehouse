###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# This doubles as the Idp::Support#idp_reconcile_email! spec — the job drives the real method, so
# the emailVerified gate and case-insensitive no-op are exercised here; there is no separate one.
#
# Idp::Support mixes into User only under the JWT arm (UserConcern), so the describe is guarded on
# AuthMethod.jwt? and these examples run only under AUTH_METHOD=jwt.
RSpec.describe Idp::SyncUserFromIdpJob, type: :job, if: AuthMethod.jwt? do
  let!(:user) { create(:user, email: 'before@example.com', first_name: 'Self', last_name: 'Serve') }
  let(:service) do
    instance_double(
      Idp::KeycloakService,
      idp_name: 'Keycloak',
      supports_email_self_service?: true,
      supports_user_management?: true,
    )
  end

  before(:each) do
    user.user_authentication_sources.create!(connector_id: 'test', connector_user_id: 'kc-1')
    user.update_column(:last_connector_id, 'test')
    allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_return(service)
    # NullStore can't hold the cooldown flag.
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
  end

  def remote_user(email:, verified: true)
    { 'id' => 'kc-1', 'email' => email, 'emailVerified' => verified }
  end

  it 'adopts an address the IdP has verified' do
    allow(service).to receive(:get_user).with(user_id: 'kc-1').and_return(remote_user(email: 'after@example.com'))

    described_class.new.perform(user_id: user.id)

    expect(user.reload.email).to eq('after@example.com')
  end

  it 'leaves the local address alone when the IdP still holds it' do
    allow(service).to receive(:get_user).and_return(remote_user(email: 'before@example.com'))

    described_class.new.perform(user_id: user.id)

    expect(user.reload.email).to eq('before@example.com')
  end

  # HUD user rows are keyed on the address, so adopting a new one without re-pointing them leaves
  # those rows stale.
  it 're-points HMIS HUD user rows from the previous address' do
    allow(service).to receive(:get_user).and_return(remote_user(email: 'after@example.com'))
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

    described_class.new.perform(user_id: user.id)
  end

  # Adopting a case-only difference would still write the column and fire a re-point whose
  # previous_email differs from the new address only in case.
  it 'treats a case-only difference as no change' do
    allow(service).to receive(:get_user).and_return(remote_user(email: 'BEFORE@example.com'))
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).not_to receive(:sync_to_hud_users)

    described_class.new.perform(user_id: user.id)

    expect(user.reload.email).to eq('before@example.com')
  end

  # Two databases, no shared commit: adopting is only safe if a failed HUD re-point rolls the new
  # address back out of users.email.
  it 'unwinds the adopted address when the HMIS re-point fails' do
    allow(service).to receive(:get_user).and_return(remote_user(email: 'after@example.com'))
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    allow(user).to receive(:sync_to_hud_users).and_raise(ActiveRecord::RecordInvalid.new(user))
    allow(Sentry).to receive(:capture_exception_with_info)

    described_class.new.perform(user_id: user.id)

    expect(user.reload.email).to eq('before@example.com')
  end

  it 'does not re-point HMIS rows when the address has not moved' do
    allow(service).to receive(:get_user).and_return(remote_user(email: 'before@example.com'))
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow(User).to receive(:find_by).with(id: user.id).and_return(user)
    expect(user).not_to receive(:sync_to_hud_users)

    described_class.new.perform(user_id: user.id)
  end

  it 'never reaches the IdP when it offers no email self-service' do
    allow(service).to receive(:supports_email_self_service?).and_return(false)
    expect(service).not_to receive(:get_user)

    described_class.new.perform(user_id: user.id)
  end

  it 'tolerates a user deleted between enqueue and run' do
    expect(service).not_to receive(:get_user)

    expect { described_class.new.perform(user_id: user.id + 1_000) }.not_to raise_error
  end

  describe 'a connector fault' do
    let(:error) { Idp::ServiceError.new('Failed to fetch user', idp_name: 'Keycloak', operation: :get_user) }

    before(:each) do
      allow(service).to receive(:get_user).and_raise(error)
    end

    # sentry-delayed_job reports whatever escapes the job, so raising is what reaches Sentry.
    it 'raises so the failure retries and reaches Sentry' do
      expect { described_class.new.perform(user_id: user.id) }.to raise_error(error)
    end

    it 'starts the connector cooldown so a broken connector stops enqueueing a job per sign-in' do
      expect { described_class.new.perform(user_id: user.id) }.to raise_error(Idp::ServiceError)

      expect(described_class.connector_paused?('test')).to be true
      expect(described_class.connector_paused?('other-connector')).to be false
    end
  end

  # Refused, and neither retried nor cooled down: the same unverified address comes back until an
  # operator turns Verify Email on for the realm.
  describe 'an address the IdP never verified' do
    before(:each) do
      allow(service).to receive(:get_user).and_return(remote_user(email: 'after@example.com', verified: false))
      allow(Sentry).to receive(:capture_exception_with_info)
    end

    it 'reports to Sentry rather than raising' do
      expect(Sentry).to receive(:capture_exception_with_info).with(
        kind_of(Idp::ServiceError),
        /Couldn't adopt IdP email for user #{user.id}/,
      )

      expect { described_class.new.perform(user_id: user.id) }.not_to raise_error
    end

    it 'leaves the local address in place' do
      described_class.new.perform(user_id: user.id)

      expect(user.reload.email).to eq('before@example.com')
    end

    # Otherwise one misconfigured realm pauses the connector and nobody else on the connector syncs.
    it 'does not pause the connector' do
      described_class.new.perform(user_id: user.id)

      expect(described_class.connector_paused?('test')).to be false
    end
  end

  # No retry resolves an address another user already holds, so report and stop.
  describe 'an address we cannot store' do
    before(:each) do
      allow(service).to receive(:get_user).and_return(remote_user(email: 'after@example.com'))
      allow(User).to receive(:find_by).with(id: user.id).and_return(user)
      allow(user).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(user))
    end

    it 'reports to Sentry rather than raising' do
      expect(Sentry).to receive(:capture_exception_with_info).with(
        kind_of(ActiveRecord::RecordInvalid),
        /Couldn't adopt IdP email for user #{user.id}/,
        hash_including(user_id: user.id),
      )

      expect { described_class.new.perform(user_id: user.id) }.not_to raise_error
    end

    it 'leaves the local address in place' do
      allow(Sentry).to receive(:capture_exception_with_info)

      described_class.new.perform(user_id: user.id)

      expect(user.reload.email).to eq('before@example.com')
    end

    it 'does not pause the connector — the connector is fine' do
      allow(Sentry).to receive(:capture_exception_with_info)

      described_class.new.perform(user_id: user.id)

      expect(described_class.connector_paused?('test')).to be false
    end
  end

  # last_connector_id names a live connector the user has no user_authentication_sources row for —
  # the row was deleted, or the connector renamed. Local data, not a connector fault, so the
  # connector is not paused.
  describe 'a user with no identity row for their connector' do
    before(:each) do
      user.user_authentication_sources.destroy_all
      allow(Sentry).to receive(:capture_exception_with_info)
    end

    it 'never reaches the IdP — there is no account to ask about' do
      expect(service).not_to receive(:get_user)

      described_class.new.perform(user_id: user.id)
    end

    it 'reports to Sentry rather than raising' do
      expect(Sentry).to receive(:capture_exception_with_info).with(
        kind_of(Idp::ServiceError),
        /Couldn't adopt IdP email for user #{user.id}/,
      )

      expect { described_class.new.perform(user_id: user.id) }.not_to raise_error
    end

    # Otherwise one user's missing row stops the connector: Idp::JwtAuthentication and
    # Idp::AccountEmailsController both skip the sync for anyone on a paused connector.
    it 'does not pause the connector, so other users still sync' do
      described_class.new.perform(user_id: user.id)

      expect(described_class.connector_paused?('test')).to be false
    end
  end

  it 'is bounded to two attempts' do
    job = described_class.new
    allow(job).to receive(:delayed_job).and_return(nil)

    expect(Delayed::Worker.max_attempts - job.calculated_attempts).to eq(2)
  end
end
