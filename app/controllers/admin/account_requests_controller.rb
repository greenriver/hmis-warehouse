###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class AccountRequestsController < ApplicationController
    include ViewableEntities
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    before_action :set_account_request, only: [:update, :destroy]

    def index
      # search
      @account_requests = account_scope.
        page(params[:page]).per(25)
    end

    def update
    end

    def convert_to_user
      if adding_admin?
        unless current_user.valid_password?(confirmation_params[:confirmation_password])
          flash[:error] = 'Account not created. Incorrect password'
          render :confirm
          return
        end
      end

      begin
        User.transaction do
          @user.skip_reconfirmation!
          @user.disable_2fa! if user_params[:otp_required_for_login] == 'false'
          @user.update(user_params)
          @user.set_viewables viewable_params
        end
      rescue Exception
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
      end
      redirect_to({ action: :index }, notice: 'User created')
    end

    def destroy
      @account_request.destroy
      respond_with(@account_request, location: account_requests_path)
    end

    private def adding_admin?
      @adming_admin ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        adming_admin = false
        existing_roles = @user.user_roles
        unless existing_roles.map(&:role).map(&:has_super_admin_permissions?).any?
          assigned_roles = user_params[:role_ids]&.select(&:present?)&.map(&:to_i) || []
          added_role_ids = assigned_roles - existing_roles.pluck(:role_id)
          added_role_ids.select(&:present?).each do |id|
            role = Role.find(id.to_i)
            if role.administrative?
              @admin_role_name = role.role_name
              adming_admin = true
            end
          end
        end
        adming_admin
      end
    end

    private def account_request_scope
      AccountRequest.pending
    end

    private def user_params
      base_params = params[:user] || ActionController::Parameters.new
      base_params.permit(
        :last_name,
        :first_name,
        :email,
        :phone,
        :agency_id,
        :receive_file_upload_notifications,
        :notify_on_vispdat_completed,
        :notify_on_client_added,
        :notify_on_anomaly_identified,
        :otp_required_for_login,
        :expired_at,
        :training_completed,
        role_ids: [],
        access_group_ids: [],
        coc_codes: [],
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
      ).tap do |result|
        result[:coc_codes] ||= []
      end
    end

    private def confirmation_params
      params.require(:user).permit(
        :confirmation_password,
      )
    end

    private def viewable_params
      params.require(:user).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        reports: [],
        cohorts: [],
        project_groups: [],
      )
    end

    private def set_account_request
      @account_request = account_request_scope.find(params[:id].to_i)
    end
  end
end
