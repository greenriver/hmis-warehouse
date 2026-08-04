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
RSpec.describe Idp::Support, type: :model, if: AuthMethod.jwt? do
  let(:user) { create(:user) }
  let(:connector_id) { 'test' }
  let(:connector_user_id) { 'kc-user-1' }

  def link_identity!(cuid: connector_user_id)
    user.user_authentication_sources.create!(connector_id: connector_id, connector_user_id: cuid)
    user.update_column(:last_connector_id, connector_id)
  end

  # reconcile_email! is deliberately excluded from this shared set: alone among the ops it has no
  # capability gate, so it raises rather than no-ops and diverges per class (see each context).
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

    # idp_reconcile_email! is the one surviving latent raise — it gates on primary_idp alone and
    # reaches NullService#get_user, which raises. The controller can never reach this (the
    # change-email tab gates off when supports_email_self_service? is false), so this model-layer
    # assertion is the only place it is exercised. Pins that a caller must gate or rescue rather
    # than call it blind on a null-attached user.
    it 'idp_reconcile_email! raises Idp::ServiceError (the surviving latent caller-discipline case)' do
      expect { user.idp_reconcile_email! }.to raise_error(Idp::ServiceError)
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
  # logout stay live. The email-adopt half (reconcile_email!) has no capability gate, so it still
  # reaches the admin-API get_user even on this class; the request specs cover that path.
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

    it 'idp_reconcile_email! is ungated by capability and still reaches the admin-API get_user' do
      allow(service).to receive(:get_user).and_return('email' => user.email, 'emailVerified' => true)
      user.idp_reconcile_email!
      expect(service).to have_received(:get_user).with(user_id: connector_user_id)
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
end
