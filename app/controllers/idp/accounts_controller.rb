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
  include Idp::SoftFailure

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
      flash[:notice] = changed_notes.join(' ')
      @user.update(account_params)
      push_profile_to_idp
      @user.sync_to_hud_users if HmisEnforcement.hmis_enabled?
    end
    redirect_to edit_account_path
  end

  # Push a committed name change to the IdP. idp_update_profile! no-ops unless the service accepts
  # writes; account_params already strips these keys when the profile is locked, so a locked user
  # never reaches here with a change anyway.
  private def push_profile_to_idp
    changes = @user.saved_changes.slice('first_name', 'last_name')
    return if changes.empty?

    attributes = changes.transform_values(&:last).symbolize_keys
    with_idp_soft_failure("Your account was saved, but we couldn't update your profile with your identity provider") do
      @user.idp_update_profile!(attributes)
    end
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
