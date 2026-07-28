###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT-arm account self-management. Credentials (password/2FA) and login history are IdP-owned, so
# this controller only edits the Warehouse-owned profile and pushes the IdP-owned identity fields
# (name) back to the IdP when the connector accepts writes. Selected at the route level under
# AuthMethod.jwt?; the Devise AccountsController is untouched.
class Idp::AccountsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    changed_notes = []
    # Name keys are absent for an IdP-managed profile (disabled inputs / stripped params), so only
    # flag a name change when the field was actually editable and submitted.
    changed_notes << 'Account name was updated.' if account_params.key?(:first_name) && (@user.first_name != account_params[:first_name] || @user.last_name != account_params[:last_name])
    changed_notes << 'User credentials were changed.' if @user.credentials != account_params[:credentials]
    changed_notes << 'Email schedule was updated.' if @user.email_schedule != account_params[:email_schedule]
    changed_notes << 'Phone number was updated.' if @user.phone != account_params[:phone]

    if changed_notes.present?
      # Nested rather than atomic: users lives in the app db and Hmis::Hud::User in the warehouse
      # db, so these are two connections with no shared commit. The nesting still means a failed
      # HUD sync or IdP push unwinds the local edit, which is the divergence worth preventing.
      GrdaWarehouseBase.transaction do
        @user.transaction do
          @user.update!(account_params)
          @user.sync_to_hud_users if HmisEnforcement.hmis_enabled?
          push_profile_to_idp
        end
      end
      flash[:notice] = changed_notes.join(' ')
    end
    redirect_to edit_account_path
  rescue ActiveRecord::RecordInvalid
    render :edit
  rescue Idp::ServiceError => e
    # The push is inside the transaction, so nothing was saved. Tell the user rather than handing
    # them a 500, and page — a self-service edit failing means the connector needs attention.
    Sentry.capture_exception_with_info(e, "Couldn't sync user #{@user.id}'s profile to the identity provider")
    flash.now[:alert] = "We couldn't save your changes: your identity provider didn't accept them (#{e.message})."
    render :edit
  end

  # Push a name change to the IdP from inside the caller's transaction, so a refused write takes the
  # local edit with it. idp_update_profile! no-ops unless the service accepts writes; account_params
  # already strips these keys when the profile is locked, so a locked user never reaches here with a
  # change anyway.
  private def push_profile_to_idp
    changes = @user.saved_changes.slice('first_name', 'last_name')
    return if changes.empty?

    attributes = changes.transform_values(&:last).symbolize_keys
    @user.idp_update_profile!(attributes)
  end

  private def account_params
    return @account_params if defined?(@account_params)

    permitted = params.require(:user).
      permit(
        :first_name,
        :last_name,
        :phone,
        :email_schedule,
        :credentials,
        :theme,
      )
    # The form disables name inputs for an IdP-managed profile; strip them defensively so a crafted
    # request can't rewrite identity fields the IdP owns.
    permitted = permitted.except(:first_name, :last_name) if @user.profile_managed_by_idp?
    @account_params = permitted
  end

  private def set_user
    @user = current_user
  end
end
