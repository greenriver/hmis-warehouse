###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Model-layer coverage for the six Idp::Support write ops, driven directly on the User
# mixin with no controller. The request specs reach these ops only through a controller
# whose earlier gate is closed for the connector/config combinations exercised here, so
# the paths with no in-method guard — reconcile on a null-attached user, the setup-email
# path, and the authenticate-only split — are reachable only from this layer.
#
# Each context builds one connector/config combination and lets the real ServiceFactory
# resolve it, so config→service resolution is exercised, not stubbed. Only the remote
# Keycloak calls are stubbed, on the memoized service instance (Idp::Support#idp_service
# caches, so the op reuses what we stub).
RSpec.describe Idp::Support, :jwt_only, type: :model do
  let(:user) { create(:user) }
  let(:connector_id) { 'test' }
  let(:connector_user_id) { 'kc-user-1' }

  def link_identity!(cuid: connector_user_id)
    user.user_authentication_sources.create!(connector_id: connector_id, connector_user_id: cuid)
    user.update_column(:last_connector_id, connector_id)
  end

  # reconcile_email! is excluded from this shared set: it gates on supports_user_management? like
  # these ops, but no-ops to nil (its "nothing moved" value) rather than :unmanaged/false.
  shared_examples 'management ops no-op without raising' do
    it 'idp_deactivate! returns :unmanaged' do
      expect(user.idp_deactivate!).to eq(:unmanaged)
    end

    it 'idp_reactivate! returns :unmanaged' do
      expect(user.idp_reactivate!).to eq(:unmanaged)
    end

    it 'idp_force_password_change! returns false' do
      expect(user.idp_force_password_change!).to be false
    end

    it 'idp_send_account_setup_email! returns false' do
      expect(user.idp_send_account_setup_email!).to be false
    end

    it 'idp_update_profile! returns false' do
      expect(user.idp_update_profile!(first_name: 'New')).to be false
    end
  end

  context 'null-detached (no connector on file)' do
    it 'resolves to a NullService' do
      expect(user.idp_service).to be_a(Idp::NullService)
      expect(user.primary_idp).to be_blank
    end

    include_examples 'management ops no-op without raising'

    it 'idp_reconcile_email! returns nil (no IdP to adopt from)' do
      expect(user.idp_reconcile_email!).to be_nil
    end

    it 'idp_profile_source is :token_claims' do
      expect(user.idp_profile_source).to eq(:token_claims)
    end
  end

  # null-attached — an auth-source row still names the connector (primary_idp present), but no
  # active ServiceConfig exists, so the service is a NullService. The ops gate on primary_idp
  # alone and would reach a raising NullService method if their own capability gate were dropped.
  context 'null-attached (connector named, config absent)' do
    before { link_identity! }

    it 'has a present primary_idp but resolves to a NullService' do
      expect(user.primary_idp).to eq(connector_id)
      expect(user.idp_service).to be_a(Idp::NullService)
    end

    include_examples 'management ops no-op without raising'

    # idp_send_account_setup_email! self-gates on supports_user_creation?, so it returns false
    # rather than reaching the raising NullService#send_execute_actions_email. (Also asserted by
    # the shared examples above; pinned separately here as the regression it guards.)
    it 'idp_send_account_setup_email! stays inert instead of reaching the raising NullService method' do
      expect(user.idp_service).not_to receive(:send_execute_actions_email)
      expect(user.idp_send_account_setup_email!).to be false
    end

    # A NullService reports supports_user_management? false, so idp_reconcile_email! self-gates
    # before reaching the raising NullService#get_user.
    it 'idp_reconcile_email! stays inert instead of reaching the raising NullService method' do
      expect(user.idp_service).not_to receive(:get_user)
      expect(user.idp_reconcile_email!).to be_nil
    end

    it 'idp_profile_source is :token_claims' do
      expect(user.idp_profile_source).to eq(:token_claims)
    end
  end

  # Covered transitively by the request specs; carried here to complete the model-layer matrix and
  # pin that each op dispatches through to its remote call with the connector_user_id on file.
  context 'keycloak-on-file, manageable' do
    let!(:config) { create(:idp_service_config, connector_id: connector_id, manage_users: true) }
    let(:service) { user.idp_service }

    before { link_identity! }

    it 'resolves to a manageable KeycloakService' do
      expect(service).to be_a(Idp::KeycloakService)
      expect(service.supports_user_management?).to be true
    end

    it 'idp_profile_source is :admin_api' do
      expect(user.idp_profile_source).to eq(:admin_api)
    end

    it 'idp_deactivate! calls deactivate_user and returns :deactivated' do
      allow(service).to receive(:deactivate_user).and_return(true)
      expect(user.idp_deactivate!).to eq(:deactivated)
      expect(service).to have_received(:deactivate_user).with(user_id: connector_user_id)
    end

    it 'idp_reactivate! calls reactivate_user and returns :reactivated' do
      allow(service).to receive(:reactivate_user).and_return(true)
      expect(user.idp_reactivate!).to eq(:reactivated)
      expect(service).to have_received(:reactivate_user).with(user_id: connector_user_id)
    end

    it 'idp_force_password_change! requests the UPDATE_PASSWORD action' do
      allow(service).to receive(:set_required_action).and_return(true)
      expect(user.idp_force_password_change!).to be true
      expect(service).to have_received(:set_required_action).with(user_id: connector_user_id, actions: ['UPDATE_PASSWORD'])
    end

    it 'idp_send_account_setup_email! sends the setup actions email' do
      allow(service).to receive(:send_execute_actions_email).and_return(true)
      expect(user.idp_send_account_setup_email!).to be true
      expect(service).to have_received(:send_execute_actions_email).
        with(user_id: connector_user_id, actions: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'])
    end

    it 'idp_update_profile! pushes the edited attributes' do
      allow(service).to receive(:update_user).and_return(true)
      expect(user.idp_update_profile!(first_name: 'New')).to be true
      expect(service).to have_received(:update_user).with(user_id: connector_user_id, attributes: { first_name: 'New' })
    end

    it 'idp_reconcile_email! leaves the address alone when the IdP matches' do
      allow(service).to receive(:get_user).and_return('email' => user.email, 'emailVerified' => true)
      expect(user.idp_reconcile_email!).to be_nil
    end

    it 'idp_reconcile_email! adopts a verified remote address and returns the previous one' do
      previous = user.email
      allow(service).to receive(:get_user).and_return('email' => 'adopted@example.com', 'emailVerified' => true)
      expect(user.idp_reconcile_email!).to eq(previous)
      expect(user.reload.email).to eq('adopted@example.com')
    end
  end

  # keycloak-on-file, authenticate-only — active config, manage_users:false. Every management
  # capability reports false so the management ops no-op, but email self-service and session
  # logout stay live. reconcile_email! self-gates on the same capability and no-ops, so this realm
  # syncs off the token instead.
  context 'keycloak-on-file, authenticate-only (manage_users:false)' do
    let!(:config) { create(:idp_service_config, connector_id: connector_id, manage_users: false) }
    let(:service) { user.idp_service }

    before { link_identity! }

    it 'resolves to a KeycloakService with management disabled' do
      expect(service).to be_a(Idp::KeycloakService)
      expect(service.supports_user_management?).to be false
    end

    include_examples 'management ops no-op without raising'

    it 'keeps email self-service and session logout live' do
      expect(service.supports_email_self_service?).to be true
      expect(service.supports_session_logout?).to be true
    end

    # get_user is an Admin API read this realm can't serve, so the reconcile no-ops rather than
    # firing a doomed request per eligible login (which would pause the connector).
    it 'idp_reconcile_email! self-gates on the missing management capability' do
      expect(service).not_to receive(:get_user)
      expect(user.idp_reconcile_email!).to be_nil
    end

    it 'idp_profile_source is :token_claims even though email self-service reports true' do
      expect(service.supports_email_self_service?).to be true
      expect(user.idp_profile_source).to eq(:token_claims)
    end
  end

  # keycloak-half-linked — active manageable config, but no matching auth-source row, so there is
  # no connector_user_id on file. The ops split: deactivate/reactivate reach idp_identity_on_file?
  # first and return :identity_missing (keeping the local flag authoritative); the remaining ops
  # reach idp_connector_user_id! and raise Idp::ServiceError before any remote call.
  context 'keycloak-half-linked (config active, no identity row)' do
    let!(:config) { create(:idp_service_config, connector_id: connector_id, manage_users: true) }

    # primary_idp present via last_connector_id, but no user_authentication_sources row for it.
    before { user.update_column(:last_connector_id, connector_id) }

    it 'resolves to a manageable KeycloakService with no identity on file' do
      expect(user.idp_service).to be_a(Idp::KeycloakService)
      expect(user.primary_idp).to eq(connector_id)
    end

    it 'idp_deactivate! returns :identity_missing (local flag stays authoritative)' do
      expect(user.idp_deactivate!).to eq(:identity_missing)
    end

    it 'idp_reactivate! returns :identity_missing (local flag stays authoritative)' do
      expect(user.idp_reactivate!).to eq(:identity_missing)
    end

    it 'idp_force_password_change! raises Idp::ServiceError at idp_connector_user_id!' do
      expect { user.idp_force_password_change! }.to raise_error(Idp::ServiceError)
    end

    it 'idp_send_account_setup_email! raises Idp::ServiceError at idp_connector_user_id!' do
      expect { user.idp_send_account_setup_email! }.to raise_error(Idp::ServiceError)
    end

    it 'idp_reconcile_email! raises Idp::ServiceError at idp_connector_user_id!' do
      expect { user.idp_reconcile_email! }.to raise_error(Idp::ServiceError)
    end

    it 'idp_update_profile! raises Idp::ServiceError at idp_connector_user_id!' do
      expect { user.idp_update_profile!(first_name: 'New') }.to raise_error(Idp::ServiceError)
    end
  end

  describe '#idp_reconcile_profile_from_claims!' do
    let(:user) { create(:user, email: 'before@example.com', first_name: 'Ada', last_name: 'Lovelace') }

    it 'adopts an address the IdP asserts as verified' do
      result = user.idp_reconcile_profile_from_claims!(email: 'after@example.com', email_verified: true)

      expect(result).to eq(previous_email: 'before@example.com')
      expect(user.reload.email).to eq('after@example.com')
    end

    it 'adopts an address when the token carries no email_verified claim at all' do
      user.idp_reconcile_profile_from_claims!(email: 'after@example.com', email_verified: nil)

      expect(user.reload.email).to eq('after@example.com')
    end

    it 'refuses an address the IdP explicitly reports as unconfirmed' do
      result = user.idp_reconcile_profile_from_claims!(email: 'after@example.com', email_verified: false)

      expect(result).to be_nil
      expect(user.reload.email).to eq('before@example.com')
    end

    it 'reports nothing moved when the address only differs in case' do
      expect(user.idp_reconcile_profile_from_claims!(email: 'BEFORE@example.com', email_verified: true)).to be_nil
    end

    it 'adopts changed names' do
      user.idp_reconcile_profile_from_claims!(first_name: 'Augusta', last_name: 'Byron')

      expect(user.reload.first_name).to eq('Augusta')
      expect(user.last_name).to eq('Byron')
    end

    it 'reports a name-only change with a nil previous_email' do
      result = user.idp_reconcile_profile_from_claims!(email: 'before@example.com', first_name: 'Augusta')

      expect(result).to eq(previous_email: nil)
    end

    it 'leaves names on file alone when the claims carry none' do
      user.idp_reconcile_profile_from_claims!(email: 'after@example.com', first_name: nil, last_name: nil)

      expect(user.reload.first_name).to eq('Ada')
      expect(user.last_name).to eq('Lovelace')
    end

    it 'returns nil when every claim matches what is already on file' do
      result = user.idp_reconcile_profile_from_claims!(
        email: 'before@example.com',
        email_verified: true,
        first_name: 'Ada',
        last_name: 'Lovelace',
      )

      expect(result).to be_nil
    end

    it 'raises when the claimed address is already taken locally' do
      create(:user, email: 'taken@example.com')

      expect { user.idp_reconcile_profile_from_claims!(email: 'taken@example.com', email_verified: true) }.
        to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
