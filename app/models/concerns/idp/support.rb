###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp::Support
  extend ActiveSupport::Concern

  def idp_service
    return Idp::ServiceFactory.for_connector(primary_idp) if primary_idp

    Idp::NullService.new
  end

  def primary_idp
    last_connector_id.presence || user_authentication_sources.order(:created_at).first&.connector_id
  end

  # The IdP owns the user's identity fields (see #profile_managed_by_idp?), so there is no local
  # email for the user to change: a self-service edit would not reach the IdP and would be
  # overwritten from the JWT on the next login (and these users have no local password for
  # update_with_password anyway). Defined as the inverse of profile ownership, the same invariant
  # OmniauthSupport holds, so the self-service and admin surfaces can't disagree.
  def email_change_enabled?
    !profile_managed_by_idp?
  end

  # The user's identity fields (name/email) are set from the JWT by Idp::UserProvisioner and
  # owned by the identity provider. The admin surface renders them read-only and does not push
  # profile edits to the IdP, so admins can't change them here.
  def profile_managed_by_idp?
    true
  end

  # Local `expired_at`-based account expiry is a Devise-authentication concept the IdP does not
  # honor, so the JWT admin surface hides the "Account Life-cycle" field and rejects the param.
  def account_expiry_enabled?
    false
  end

  # Whether the JWT-arm admin surface should offer the "Force Password Reset" action, which only
  # pushes an UPDATE_PASSWORD required action to the IdP (see #idp_force_password_change!). False
  # for an account with no IdP link at all: there is nothing to push, so the action is a
  # guaranteed no-op and the menu hides it rather than confirm-then-do-nothing. A present-but-
  # broken link (orphaned connector / unreachable IdP) still returns true so the action runs and
  # soft-warns instead of silently disappearing. Mirrors the #idp_force_password_change! guard.
  def idp_password_management_enabled?
    primary_idp.present?
  end

  # Under JWT credentials/2FA are IdP-managed, so admins are never asked to re-confirm
  # their local password before privileged actions (the Devise arm keeps
  # OmniauthSupport#confirm_password_for_admin_actions?). Defined here so any code reachable
  # in both modes resolves the predicate; the JWT admin surface simply never renders the field.
  def confirm_password_for_admin_actions?
    false
  end

  # Best-effort IdP writes. Return truthy when a push actually landed and `false` when the user
  # has no IdP link at all (no last_connector_id and no authentication source — a warehouse-local
  # or legacy account), in which case there is nothing to push and we no-op silently rather than
  # nag about an IdP the account was never part of. They still raise Idp::ServiceError on a real
  # failure (unmanageable connector, IdP unreachable, or a connector link with no id on file);
  # the admin controller owns the fail-soft policy after the authoritative local change commits.
  # The `false` return also lets a push-only action (expire_password) avoid claiming a success
  # that never happened.
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

  private

  # The user's stable id within the upstream IdP for its primary connector.
  def idp_connector_user_id!
    connector = primary_idp
    source = user_authentication_sources.where(connector_id: connector).order(:created_at).first if connector
    id = source&.connector_user_id
    raise Idp::ServiceError.new('No IdP identity on file for this user', operation: :connector_user_id) if id.blank?

    id
  end
end
