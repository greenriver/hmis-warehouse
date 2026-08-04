###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# user model mixin
module Idp::Support
  extend ActiveSupport::Concern

  def idp_service
    return @idp_service if defined?(@idp_service)

    @idp_service = primary_idp ? Idp::ServiceFactory.for_connector(primary_idp) : Idp::NullService.new
  end

  def primary_idp
    last_connector_id.presence || primary_auth_source&.connector_id
  end

  # The IdP owns the user's identity fields unless its service can push our edits back to it
  def email_change_enabled?
    !profile_managed_by_idp?
  end

  # A service we can't even build (e.g. misconfigured Keycloak) is treated as locked — the safe
  # default that keeps the admin form renderable; management actions surface the real config
  # error through their own soft-failure handling.
  def profile_managed_by_idp?
    !idp_service.supports_profile_updates?
  rescue Idp::ServiceError
    true
  end

  # Local `expired_at`-based account expiry not supported
  def account_expiry_enabled?
    false
  end

  # The JWT arm never runs Devise/Warden, so nothing populates login_activities.
  def login_locations_enabled?
    false
  end

  # Whether the JWT-arm admin surface should offer the "Force Password Reset" action
  def idp_password_management_enabled?
    idp_service.supports_user_management?
  rescue Idp::ServiceError
    false
  end

  # Under JWT credentials are IdP-managed, so admins cannot re-confirm
  def confirm_password_for_admin_actions?
    false
  end

  def idp_deactivate!
    return false unless primary_idp

    idp_service.deactivate_user(user_id: idp_connector_user_id!)
  end

  def idp_reactivate!
    return false unless primary_idp

    idp_service.reactivate_user(user_id: idp_connector_user_id!)
  end

  def idp_force_password_change!
    return false unless primary_idp

    idp_service.set_required_action(user_id: idp_connector_user_id!, actions: ['UPDATE_PASSWORD'])
  end

  # Email the user a link to set their password and verify their email, used to hand a freshly
  # provisioned account off to its owner without the admin setting a credential.
  def idp_send_account_setup_email!
    return false unless primary_idp
    return false unless idp_service.supports_user_creation?

    idp_service.send_execute_actions_email(user_id: idp_connector_user_id!, actions: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'])
  end

  # Push admin-edited first_name/last_name/email to the IdP. No-ops unless the service can accept
  # the write back (the same capability that unlocks the fields in the first place).
  def idp_update_profile!(attributes)
    return false unless primary_idp
    return false unless idp_service.supports_profile_updates?

    idp_service.update_user(user_id: idp_connector_user_id!, attributes: attributes)
  end

  private

  # Unlike the render-time predicates above, this deliberately does not rescue Idp::ServiceError. A
  # deactivated or removed config resolves to a NullService (returns false) and the local write still
  # proceeds — the local `active` flag is what admits the user here. But a config we can't build
  # (blank client_id, unregistered provider) means an IdP holds this account and we can't reach it,
  # so the raise aborts the write rather than letting local state diverge. Deactivate the
  # Idp::ServiceConfig to fall back to the NullService case.
  def idp_user_management_available?
    return false unless primary_idp

    idp_service.supports_user_management?
  end

  def primary_auth_source
    return @primary_auth_source if defined?(@primary_auth_source)

    @primary_auth_source = if last_connector_id.presence
      user_authentication_sources.where(connector_id: last_connector_id).order(:created_at).first
    else
      user_authentication_sources.order(:created_at).first
    end
  end

  # The user's stable id within the upstream IdP for its primary connector.
  def idp_connector_user_id!
    id = primary_auth_source&.connector_user_id
    if id.blank?
      raise Idp::ServiceError.new(
        'No IdP identity on file for this user',
        operation: :connector_user_id,
        # Local data rather than an IdP fault, so the same answer comes back on retry. Callers that
        # treat transient errors as connector-wide — Idp::SyncUserFromIdpJob's cooldown — would
        # otherwise let one user's missing row stop the connector for everyone on it.
        transient: false,
      )
    end

    id
  end
end
