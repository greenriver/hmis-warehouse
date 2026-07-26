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
  include Idp::SoftFailure

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
    warning = "Your email was changed with #{idp_name}, but we couldn't adopt the new address"
    previous_email = with_idp_soft_failure(warning, now: true) do
      @user.idp_reconcile_email!
    end
    return if previous_email.blank?

    @user.sync_to_hud_users(previous_email: previous_email) if HmisEnforcement.hmis_enabled?
    flash.now[:notice] = 'Account email was updated.'
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
