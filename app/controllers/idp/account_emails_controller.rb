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

  # Records that a change is expected before handing the browser over, since the user may never come
  # back here — see Idp::KeycloakService#account_client_id.
  def begin_change
    action_url = @user.email_change_enabled? && @user.account_action_url(action: 'UPDATE_EMAIL', redirect_uri: edit_account_email_url)
    raise 'Attempt to change email but when feature is not enabled' if action_url.blank?

    Idp::EmailChangePending.mark!(@user)
    # An earlier request may hold a full-interval reservation, which would outlast the change.
    Idp::SyncThrottle.release!(@user)
    Rails.logger.info("User #{@user.id} started an email change at #{@user.idp_service.idp_name}")

    redirect_to action_url, allow_other_host: true
  end

  # On every render, not just a return trip: Keycloak picks where the user lands, and after a mailbox
  # confirmation that isn't here at all. Costs one Admin API read on a rarely visited tab.
  private def reconcile_email_from_idp
    idp_name = @user.idp_service.idp_name

    # Nested rather than atomic: users lives in the app db and Hmis::Hud::User in the warehouse db,
    # so these are two connections with no shared commit. The nesting still means a failed HUD sync
    # unwinds the adopted address instead of leaving HMIS rows keyed on an email we no longer hold.
    GrdaWarehouseBase.transaction do
      @user.transaction do
        @previous_email = @user.idp_reconcile_email!
        @user.sync_to_hud_users(previous_email: @previous_email) if @previous_email.present? && HmisEnforcement.hmis_enabled?
      end
    end
    return if @previous_email.blank?

    Idp::EmailChangePending.clear!(@user)
    flash.now[:notice] = 'Account email was updated.'
  rescue Idp::ServiceError => e
    # Nothing was written, so there's no state to unwind and no reason to fail the page. flash.now,
    # so the warning doesn't come back on the next visit.
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't adopt the new address: #{e.message}" if change_expected?
    # A non-transient failure won't resolve on its own, so stop hurrying the read-back along. After
    # the copy above, which reads the marker.
    Idp::EmailChangePending.clear!(@user) unless e.transient?
  rescue ActiveRecord::RecordInvalid => e
    # The IdP moved the address but we can't store it — taken here, or malformed. Reload to drop the
    # rejected value. Alerted either way, and the marker goes: the records have diverged and only
    # support can close it.
    reason = e.record.errors.full_messages.join(', ')
    @user.reload
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}: #{reason}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't save the new address here. Please contact support."
    Idp::EmailChangePending.clear!(@user)
  end

  # Only asked for while a change is in flight — an abandoned one can leave an address behind at the
  # IdP indefinitely.
  private def pending_email_from_idp
    return nil if @previous_email.present?
    return nil unless Idp::EmailChangePending.pending?(@user)

    @user.idp_pending_email
  rescue Idp::ServiceError
    # Display only, and the reconcile above already reported the failure.
    nil
  end

  # Gates the apology copy, not the reconciliation. An admin-side edit to an unverified address makes
  # this tab raise on every visit, and a user shouldn't be told we failed at a change they never made.
  private def change_expected?
    params[:kc_action_status] == 'success' || Idp::EmailChangePending.pending?(@user)
  end

  private def set_user
    @user = current_user
  end
end
