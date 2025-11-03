###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccountEmailsController < ApplicationController
  before_action :set_user

  def edit
    @user.set_initial_two_factor_secret!
    render 'accounts/edit'
  end

  def update
    new_email = account_params[:email]

    if @user.email == new_email
      redirect_to edit_account_email_path
      return
    end

    # Check if user's IDP supports profile updates
    if @user.idp_supports_profile_updates?
      # Update email via IDP
      if update_email_via_idp(new_email)
        flash[:notice] = 'Account email was updated.'
        @user.update(email: new_email)
      else
        flash[:alert] = 'Unable to change email address'
      end
    else
      # IDP doesn't support email updates - show error
      flash[:alert] = 'Email changes are not available. Please contact your administrator or update your profile in your Identity Provider.'
    end

    redirect_to edit_account_email_path
  end

  private

  def account_params
    params.require(:user).
      permit(
        :email,
      )
  end

  def set_user
    @user = current_user

    return redirect_to edit_account_path, alert: 'Change email is not available.' unless @user.email_change_enabled?
  end

  # Update user email via IDP service.
  #
  # @param new_email [String] New email address
  # @return [Boolean] true if update successful, false otherwise
  def update_email_via_idp(new_email)
    return false unless @user.primary_idp.present?

    auth_source = @user.enabled_authentication_sources.find_by(connector_id: @user.primary_idp)
    return false unless auth_source&.connector_user_id.present?

    begin
      @user.idp_service.update_user(
        user_id: auth_source.connector_user_id,
        attributes: { email: new_email },
      )
      true
    rescue Idp::ServiceError => e
      Rails.logger.error "Failed to update email in IDP: #{e.message}"
      flash[:alert] = "Failed to update email in #{@user.idp_service.idp_name}: #{e.message}"
      false
    end
  end
end
