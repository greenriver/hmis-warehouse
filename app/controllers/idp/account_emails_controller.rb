###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT-arm email self-management, read-only. Email is an identity field the IdP owns end to end: the
# user changes it inside the IdP through an UPDATE_EMAIL deep-link, the IdP verifies the mailbox,
# and the Warehouse adopts the result when the browser comes back. There is no local write path, so
# nothing here can commit an address the IdP has not verified.
class Idp::AccountEmailsController < ApplicationController
  before_action :set_user

  def edit
    reconcile_email_from_idp if reconcilable_return_trip?
  end

  # Keycloak appends kc_action_status to redirect_uri after an application-initiated action, which is
  # what separates a return trip from an ordinary visit to this tab. Only 'success' means something
  # completed; 'cancelled' and 'error' leave users.email alone. The password and 2FA actions on this
  # tab return here too, so their success lands in this branch as well — #idp_reconcile_email! reads
  # the address back and no-ops when it hasn't moved, so that costs an Admin API read, not a wrong
  # write. The capability check pairs with it: a status from an IdP that offers no Update Email action
  # is noise, and an IdP whose service won't build answers false, so the read-only tab renders its
  # copy instead of chasing a reconciliation.
  private def reconcilable_return_trip?
    params[:kc_action_status] == 'success' && @user.email_change_enabled?
  end

  private def reconcile_email_from_idp
    idp_name = @user.idp_service.idp_name
    previous_email = nil

    # Nested rather than atomic: users lives in the app db and Hmis::Hud::User in the warehouse db,
    # so these are two connections with no shared commit. The nesting still means a failed HUD sync
    # unwinds the adopted address instead of leaving HMIS rows keyed on an email we no longer hold.
    GrdaWarehouseBase.transaction do
      @user.transaction do
        previous_email = @user.idp_reconcile_email!
        @user.sync_to_hud_users(previous_email: previous_email) if previous_email.present? && HmisEnforcement.hmis_enabled?
      end
    end
    return if previous_email.blank?

    flash.now[:notice] = 'Account email was updated.'
  rescue Idp::ServiceError => e
    # An unverified address or a failed Admin API read — either way nothing was written here, so
    # there is no local state to unwind and no reason to fail the page. flash.now, because the
    # warning belongs to this render and shouldn't scold the user again on their next visit.
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't adopt the new address: #{e.message}"
  rescue ActiveRecord::RecordInvalid => e
    # The IdP moved the address but we can't store it — already taken here, or malformed. Reload to
    # drop the rejected value so the tab shows what we actually hold, and page: reconciliation only
    # runs on a return trip, so nothing retries and users.email stays stale until someone intervenes.
    reason = e.record.errors.full_messages.join(', ')
    @user.reload
    Sentry.capture_exception_with_info(e, "Couldn't adopt #{idp_name} email for user #{@user.id}: #{reason}")
    flash.now[:alert] = "Your email was changed with #{idp_name}, but we couldn't save the new address here. Please contact support."
  end

  private def set_user
    @user = current_user
  end
end
