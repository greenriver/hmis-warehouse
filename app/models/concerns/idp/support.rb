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

  # Whether the user can change their own email at the IdP, which collects the new address and
  # verifies the mailbox before it becomes real. The Warehouse never edits email in this arm, so
  # this gates the deep-link, not the Email tab. A service we can't build answers false, leaving
  # the read-only tab with its explanatory copy.
  def email_change_enabled?
    idp_service.supports_email_self_service?
  rescue Idp::ServiceError
    false
  end

  # A service we can't even build (e.g. misconfigured Keycloak) is treated as locked — the safe
  # default that keeps the admin form renderable; management actions surface the real config
  # error through their own soft-failure handling.
  def profile_managed_by_idp?
    !idp_service.supports_profile_updates?
  rescue Idp::ServiceError
    true
  end

  # Under JWT there is no in-app password; credential management is delegated to the IdP's
  # account console. Defined for both-mode-reachable callers even though the JWT account surface
  # never renders the change-password tab (parity with confirm_password_for_admin_actions?).
  def password_change_enabled?
    false
  end

  # Deep-link to the IdP's self-service credential console (password/2FA), or nil when the IdP
  # has none — in which case the account page shows static "managed by your identity provider"
  # text instead of a link. A service we can't build is treated as no-console.
  def account_console_url
    idp_service.account_console_url
  rescue Idp::ServiceError
    nil
  end

  # Deep-link that takes the current user straight into a single self-service action
  # (password change, 2FA setup) and returns them to redirect_uri. Only valid for the
  # signed-in user; redirect_uri is supplied by the caller, which owns request context.
  def account_action_url(action:, redirect_uri:)
    idp_service.account_action_url(action: action, redirect_uri: redirect_uri)
  rescue Idp::ServiceError
    nil
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
    primary_idp.present?
  end

  # Under JWT credentials are IdP-managed, so admins cannot re-confirm
  def confirm_password_for_admin_actions?
    false
  end

  def idp_deactivate!
    return false unless idp_user_management_available?

    idp_service.deactivate_user(user_id: idp_connector_user_id!)
  end

  def idp_reactivate!
    return false unless idp_user_management_available?

    idp_service.reactivate_user(user_id: idp_connector_user_id!)
  end

  def idp_force_password_change!
    return false unless idp_user_management_available?

    idp_service.set_required_action(user_id: idp_connector_user_id!, actions: ['UPDATE_PASSWORD'])
  end

  # Email the user a link to set their password and verify their email, used to hand a freshly
  # provisioned account off to its owner without the admin setting a credential.
  def idp_send_account_setup_email!
    return false unless primary_idp

    idp_service.send_execute_actions_email(user_id: idp_connector_user_id!, actions: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'])
  end

  # Adopt the IdP's address after the user completed an Update Email action there — the IdP collected
  # it and verified the mailbox, so it is authoritative. Returns the address we replaced when it
  # moved, nil otherwise; callers need the old one to re-point HMIS user rows keyed on it. Compared
  # case-insensitively, because a case-only difference isn't a change worth a write and an HMIS sync.
  #
  # The JWT claim can't serve here: oauth2-proxy still holds the pre-change token when the browser
  # returns, so payload_email is the old address (and under email-as-username, the old username).
  #
  # @raise [Idp::ServiceError] the IdP holds the new address but hasn't verified the mailbox
  # @raise [ActiveRecord::RecordInvalid] the new address can't be stored here (taken, or malformed)
  def idp_reconcile_email!
    return nil unless primary_idp

    representation = idp_service.get_user(user_id: idp_connector_user_id!)
    remote_email = representation['email'].presence
    return nil if remote_email.blank? || remote_email.casecmp?(email)

    # A verified mailbox is what makes the IdP authoritative. Enforced here rather than trusted from
    # realm config: with Verify Email off, Keycloak applies a new address immediately, and adopting
    # that would leave an unproven address in users.email — the thing routing the change through the
    # IdP exists to prevent. Also covers the not-yet-clicked window, when the IdP has already
    # recorded the pending address.
    unless representation['emailVerified']
      raise Idp::ServiceError.new(
        "#{idp_service.idp_name} has not verified #{remote_email}",
        idp_name: idp_service.idp_name,
        operation: :get_user,
      )
    end

    previous_email = email
    update!(email: remote_email)

    previous_email
  end

  # Push admin-edited first_name/last_name/email to the IdP. No-ops unless the service can accept
  # the write back (the same capability that unlocks the fields in the first place).
  def idp_update_profile!(attributes)
    return false unless primary_idp
    return false unless idp_service.supports_profile_updates?

    idp_service.update_user(user_id: idp_connector_user_id!, attributes: attributes)
  end

  private

  # A connector whose config was deactivated or removed resolves to a NullService, which answers
  # false. Activation changes still have to land locally in that case: the local `active` flag is
  # what admits the user to the Warehouse, and withholding the flip because the IdP link is gone
  # would leave them enabled here.
  #
  # A connector we can't build (blank client_id, unregistered provider) is a different animal and
  # deliberately not rescued here: it means there is an IdP holding this account that we are failing
  # to reach, so the raise aborts the local write instead of quietly diverging from it. Deactivating
  # the Idp::ServiceConfig is the escape hatch that turns such an account back into the NullService
  # case. Contrast the render-time predicates above, which do rescue — a form has to render, but a
  # write does not have to commit.
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
    raise Idp::ServiceError.new('No IdP identity on file for this user', operation: :connector_user_id) if id.blank?

    id
  end
end
