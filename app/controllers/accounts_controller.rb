###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AccountsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    changed_notes = []

    # Fields that can be updated locally (not managed by IDP)
    local_fields = {}
    local_fields[:credentials] = account_params[:credentials] if @user.credentials != account_params[:credentials]
    local_fields[:email_schedule] = account_params[:email_schedule] if @user.email_schedule != account_params[:email_schedule]
    local_fields[:theme] = account_params[:theme] if @user.theme != account_params[:theme]

    changed_notes << 'User credentials were changed.' if local_fields[:credentials].present?
    changed_notes << 'Email schedule was updated.' if local_fields[:email_schedule].present?
    changed_notes << 'Theme was updated.' if local_fields[:theme].present?

    # Fields that may need IDP updates (name, phone)
    idp_fields = {}
    if @user.idp_supports_profile_updates?
      # User's IDP supports profile updates - update via IDP
      idp_fields[:first_name] = account_params[:first_name] if @user.first_name != account_params[:first_name]
      idp_fields[:last_name] = account_params[:last_name] if @user.last_name != account_params[:last_name]
      idp_fields[:phone] = account_params[:phone] if @user.phone != account_params[:phone]

      changed_notes << 'Account name was updated.' if idp_fields[:first_name].present? || idp_fields[:last_name].present?
      changed_notes << 'Phone number was updated.' if idp_fields[:phone].present?

      # Update via IDP if there are changes
      update_profile_via_idp(idp_fields) if idp_fields.any?
    elsif @user.first_name != account_params[:first_name] ||
          @user.last_name != account_params[:last_name] ||
          @user.phone != account_params[:phone]
      # IDP doesn't support profile updates - reject changes to these fields
      # These fields are managed by the IDP and would be overwritten on next login
      flash[:alert] = 'Name and phone fields are managed by your Identity Provider and cannot be updated here.'
      redirect_to edit_account_path
      return
    end

    # Update local database with all changes
    if changed_notes.present?
      flash[:notice] = changed_notes.join(' ')
      update_params = local_fields.merge(idp_fields)
      @user.update(update_params)
    end

    redirect_to edit_account_path
  end

  def locations
    @pagy, @locations = pagy(@user.login_activities.order(created_at: :desc), items: 50)
  end

  private

  def account_params
    params.require(:user).
      permit(
        :first_name,
        :last_name,
        :phone,
        :email_schedule,
        :credentials,
        :theme,
      )
  end

  def set_user
    @user = current_user
  end

  # Update user profile via IDP service.
  #
  # @param attributes [Hash] Hash of attributes to update (e.g., { first_name: 'John', phone: '123-456-7890' })
  def update_profile_via_idp(attributes)
    return unless @user.primary_idp.present?

    auth_source = @user.enabled_authentication_sources.find_by(connector_id: @user.primary_idp)
    return unless auth_source&.connector_user_id.present?

    begin
      @user.idp_service.update_user(
        user_id: auth_source.connector_user_id,
        attributes: attributes,
      )
    rescue Idp::ServiceError => e
      Rails.logger.error "Failed to update user profile in IDP: #{e.message}"
      flash[:alert] = "Failed to update profile in #{@user.idp_service.idp_name}: #{e.message}"
    end
  end
end
