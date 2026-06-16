###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::JwtUser, type: :model do
  let(:user) { create(:user) }
  let(:jwt_helper) do
    instance_double(
      Idp::JwtHelper,
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

      it 'creates a user with agency_id: 0 when no user matches' do
        helper = instance_double(
          Idp::JwtHelper,
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

    context 'when a soft-deleted record for the pair already exists' do
      let(:other_user) { create(:user) }

      # The pair's live link is gone (soft-deleted), so the JWT resolves to
      # `user` by email. The provisioner never inspects the deleted record's
      # owner, so the same code path covers both a same-user and (as here) a
      # different-user record; the different-user case is the stronger guard
      # since it also proves we never restore or re-point someone else's row.
      before do
        source = other_user.user_authentication_sources.create!(
          connector_id: 'test-idp',
          connector_user_id: 'ext-user-1',
        )
        source.destroy
      end

      it 'links the resolved user with a fresh row and leaves the old record untouched' do
        result = User.find_or_create_from_jwt(jwt_helper)
        expect(result).to eq(user)

        live = user.user_authentication_sources.find_by(connector_id: 'test-idp', connector_user_id: 'ext-user-1')
        expect(live).to be_present

        # the old record is untouched (still owned by other_user, still deleted),
        # and the new link is a fresh row rather than a restore of it
        deleted = Idp::UserAuthenticationSource.only_deleted.find_by(connector_id: 'test-idp', connector_user_id: 'ext-user-1')
        expect(deleted.user_id).to eq(other_user.id)
        expect(deleted.deleted_at).to be_present
        expect(live.id).not_to eq(deleted.id)
      end
    end
  end
end
