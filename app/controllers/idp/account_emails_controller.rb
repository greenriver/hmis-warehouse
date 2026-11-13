###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Read-only. The user changes their email at the IdP through an UPDATE_EMAIL deep-link, and we adopt
# the result the next time we read the account back. There is no local write path.
class Idp::AccountEmailsController < ApplicationController
  before_action :set_user

  def edit
    return unless @user.email_change_enabled?
    # The sync job already found this connector broken, and this is a page people refresh.
    return if Idp::SyncUserFromIdpJob.connector_paused?(@user.last_connector_id)

    reconcile_email_from_idp
    @pending_email = pending_email_from_idp
  end

  def begin_change
    action_url = @user.email_change_enabled? && @user.account_action_url(action: 'UPDATE_EMAIL', redirect_uri: edit_account_email_url)
    raise 'Attempt to change email when feature is not enabled' if action_url.blank?

    Rails.logger.info("User #{@user.id} started an email change at #{@user.idp_service.idp_name}")

    redirect_to action_url, allow_other_host: true
  end

  # Reconciles on each load of this page to catch email de-synchronization issues. We may replace this
  # with a custom webhook from keycloak in the future
  private def reconcile_email_from_idp
    idp_name = @user.idp_service.idp_name

    # users (app db) and Hmis::Hud::User (warehouse db) are separate connections with no shared
    # commit, so this isn't atomic. The nesting still rolls the email change back if the HUD sync
    # raises; only a failure between the two commits can leave them diverged.
    GrdaWarehouseBase.transaction do
      @user.transaction do
        @previous_email = @user.idp_reconcile_email!
        @user.sync_to_hud_users(previous_email: @previous_email) if @previous_email.present? && HmisEnforcement.hmis_enabled?
      end
    end
    return if @previous_email.blank?

    flash.now[:notice] = 'Account email was updated.'
  rescue Idp::ServiceError => e
    # Nothing was written, so there's no state to roll back and no reason to fail the page.
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't adopt the new address: #{e.message}" if change_expected?
  rescue ActiveRecord::RecordInvalid => e
    # The IdP moved the address but we can't store it — taken here, or malformed. Reload to drop the
    # rejected value. Alerted either way: the records have diverged and only support can close it.
    reason = e.record.errors.full_messages.join(', ')
    @user.reload
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}: #{reason}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't save the new address here. Please contact support."
  end

  # Nothing pending to show once reconcile adopted the change: the new address is already live.
  private def pending_email_from_idp
    return nil if @previous_email.present?

    @user.idp_pending_email
  rescue Idp::ServiceError
    # Display only, and #reconcile_email_from_idp already reported this ServiceError to Sentry.
    nil
  end

  # Gates the apology copy, not the reconciliation. An admin-side edit to an unverified address makes
  # this tab raise on every visit, and a user shouldn't be told we failed at a change they never made.
  # Set by Keycloak on the return trip from the UPDATE_EMAIL action.
  private def change_expected?
    params[:kc_action_status] == 'success'
  end

  # Token holder, not current_user: under impersonation these differ, and begin_change redirects the
  # browser to Keycloak under the token holder's session — reconciling current_user would adopt the
  # change into the impersonated account instead.
  private def set_user
    @user = idp_token_holder
  end
end
