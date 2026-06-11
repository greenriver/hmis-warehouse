###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JwtUser, type: :model do
  let(:user) { create(:user) }
  let(:jwt_helper) do
    instance_double(
      JwtHelper,
      token?: true,
      valid?: true,
      connector_id: 'test-idp',
      connector_user_id: 'ext-user-1',
      payload_email: user.email,
      first_name: 'Test',
      last_name: 'User',
    )
  end

  describe '.find_from_jwt' do
    it 'returns nil when valid? is false' do
      allow(jwt_helper).to receive(:valid?).and_return(false)
      expect(User.find_from_jwt(jwt_helper)).to be_nil
    end

    it 'returns nil when connector_id is nil (fail-closed)' do
      allow(jwt_helper).to receive(:connector_id).and_return(nil)
      expect(User.find_from_jwt(jwt_helper)).to be_nil
    end

    it 'returns nil when connector_user_id is nil (fail-closed)' do
      allow(jwt_helper).to receive(:connector_user_id).and_return(nil)
      expect(User.find_from_jwt(jwt_helper)).to be_nil
    end

    it 'finds a user by Authentication Source when one exists' do
      user.user_authentication_sources.create!(
        connector_id: 'test-idp',
        connector_user_id: 'ext-user-1',
      )
      expect(User.find_from_jwt(jwt_helper)).to eq(user)
    end

    it 'falls back to email when no Authentication Source exists' do
      expect(User.find_from_jwt(jwt_helper)).to eq(user)
    end

    it 'is read-only on the email-fallback path' do
      User.find_from_jwt(jwt_helper)
      expect(user.user_authentication_sources).to be_empty
      expect(user.reload.last_connector_id).to be_nil
    end

    it 'returns nil when no user matches by either path' do
      allow(jwt_helper).to receive(:payload_email).and_return('nobody@example.com')
      expect(User.find_from_jwt(jwt_helper)).to be_nil
    end
  end

  describe '.find_or_create_from_jwt' do
    # Fail-closed claim checks live in the shared provisioner gate and are
    # covered exhaustively under .find_from_jwt; this is just a smoke test that
    # this entry point routes through the same gate.
    it 'returns nil when valid? is false' do
      allow(jwt_helper).to receive(:valid?).and_return(false)
      expect(User.find_or_create_from_jwt(jwt_helper)).to be_nil
    end

    context 'with auto-creation enabled' do
      before { AppConfigProperty.create!(key: 'idp/auto_create_user', value: 'true') }

      it 'finds by auth source even when the JWT email no longer matches' do
        user.user_authentication_sources.create!(
          connector_id: 'test-idp',
          connector_user_id: 'ext-user-1',
        )
        user.update_columns(email: 'changed@example.com')

        result = User.find_or_create_from_jwt(jwt_helper)
        expect(result).to eq(user)
      end

      it 'updates last_connector_id when the connector changes' do
        user.update_column(:last_connector_id, 'old-idp')
        User.find_or_create_from_jwt(jwt_helper)
        expect(user.reload.last_connector_id).to eq('test-idp')
      end

      it 'creates a user with agency_id: 0 when no user matches' do
        helper = instance_double(
          JwtHelper,
          token?: true,
          valid?: true,
          connector_id: 'test-idp',
          connector_user_id: 'ext-user-new',
          payload_email: 'newuser@example.com',
          first_name: 'New',
          last_name: 'Person',
        )
        result = User.find_or_create_from_jwt(helper)
        expect(result).to be_persisted
        expect(result.email).to eq('newuser@example.com')
        expect(result.agency_id).to eq(0)
        expect(result.user_authentication_sources.where(connector_id: 'test-idp', connector_user_id: 'ext-user-new')).to exist
      end

      it 're-vivifies a soft-deleted Authentication Source without leaving orphaned rows' do
        auth = user.user_authentication_sources.create!(
          connector_id: 'test-idp',
          connector_user_id: 'ext-user-1',
        )
        auth.destroy

        result = User.find_or_create_from_jwt(jwt_helper)
        expect(result).to eq(user)

        all_rows = UserAuthenticationSource.unscoped.where(connector_id: 'test-idp', connector_user_id: 'ext-user-1')
        expect(all_rows.count).to eq(1)
        # the original row is restored, not recreated
        expect(all_rows.first.id).to eq(auth.id)
        expect(all_rows.first.deleted_at).to be_nil
      end
    end

    context 'without auto-creation' do
      it 'provisions an Authentication Source and last_connector_id for an existing user' do
        result = User.find_or_create_from_jwt(jwt_helper)
        expect(result).to eq(user)
        expect(user.user_authentication_sources.where(connector_id: 'test-idp', connector_user_id: 'ext-user-1')).to exist
        expect(user.reload.last_connector_id).to eq('test-idp')
      end

      it 'does NOT create a user when idp/auto_create_user is absent' do
        allow(jwt_helper).to receive(:payload_email).and_return('nobody@example.com')
        expect(User.find_or_create_from_jwt(jwt_helper)).to be_nil
      end

      it 'does NOT create a user when idp/auto_create_user is false' do
        AppConfigProperty.create!(key: 'idp/auto_create_user', value: 'false')
        allow(jwt_helper).to receive(:payload_email).and_return('nobody@example.com')
        expect(User.find_or_create_from_jwt(jwt_helper)).to be_nil
      end
    end

    context 'when the connector pair is already linked to a different user' do
      let(:other_user) { create(:user) }

      # The pair's live link is gone (soft-deleted), so the JWT resolves to
      # `user` by email; the surviving tombstone still belongs to `other_user`.
      # When the provisioner tries to re-vivify that tombstone it detects the
      # user mismatch — the misconfiguration the Sentry guard is meant to catch.
      before do
        source = other_user.user_authentication_sources.create!(
          connector_id: 'test-idp',
          connector_user_id: 'ext-user-1',
        )
        source.destroy
      end

      it 'notifies Sentry and does not transfer the link' do
        expect(Sentry).to receive(:capture_message).
          with('IdP: connector pair already linked to a different user', hash_including(level: :error))

        result = User.find_or_create_from_jwt(jwt_helper)
        expect(result).to eq(user)
        expect(user.user_authentication_sources).to be_empty

        # the tombstone is left untouched: still owned by other_user, still deleted
        tombstone = UserAuthenticationSource.unscoped.find_by(connector_id: 'test-idp', connector_user_id: 'ext-user-1')
        expect(tombstone.user_id).to eq(other_user.id)
        expect(tombstone.deleted_at).to be_present
      end
    end
  end
end
