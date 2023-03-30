###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class UsersController < ApplicationController
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!, except: [:stop_impersonating]
    before_action :set_user, only: [:edit, :unlock, :confirm, :update, :destroy, :impersonate, :un_expire]
    before_action :require_can_impersonate_users!, only: [:impersonate]
    after_action :log_user, only: [:show, :edit, :update, :destroy, :unlock, :un_expire]
    helper_method :sort_column, :sort_direction

    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      # search
      @users = if params[:q].present?
        user_scope.text_search(params[:q])
      else
        user_scope
      end

      @users = @users.
        preload(:access_controls).
        order(sort_column => sort_direction)

      @pagy, @users = pagy(@users)
    end

    def edit
      @user.set_initial_two_factor_secret!
    end

    def unlock
      @user.unlock_access!
      redirect_to({ action: :index }, notice: 'User unlocked')
    end

    def un_expire
      @user.update_last_activity!
      redirect_to({ action: :index }, notice: 'User re-activated')
    end

    def confirm
      update unless adding_admin?
    end

    def impersonate
      become = User.find(params[:become_id].to_i)
      impersonate_user(become)
      redirect_to root_path
    end

    def stop_impersonating
      stop_impersonating_user
      redirect_to root_path
    end

    def update
      if adding_admin? && current_user.confirm_password_for_admin_actions? && !current_user.valid_password?(confirmation_params[:confirmation_password])
        flash[:error] = 'User not updated. Incorrect password'
        render :confirm
        return
      end

      begin
        User.transaction do
          @user.skip_reconfirmation!
          # Associations don't play well with acts_as_paranoid, so manually clean up user ACLs
          @user.user_access_controls.where.not(access_control_id: assigned_acl_ids).destroy_all
          @user.disable_2fa! if user_params[:otp_required_for_login] == 'false'
          @user.update!(user_params)
        end
      rescue Exception
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
      end
      redirect_to({ action: :index }, notice: 'User updated')
    end

    def destroy
      @user.paper_trail_event = 'deactivate'
      @user.update(active: false)
      redirect_to({ action: :index }, notice: "User #{@user.name} deactivated")
    end

    def title_for_show
      @user.name
    end
    alias title_for_edit title_for_show
    alias title_for_destroy title_for_show
    alias title_for_update title_for_show

    def title_for_index
      'User List'
    end

    private def adding_admin?
      @adming_admin ||= begin # rubocop:disable Naming/MemoizedInstanceVariableName
        adming_admin = false
        existing_roles = @user.roles

        # If we don't already have a role granting an admin permission, and we're assinging some
        # ACLs (with associated roles)
        if existing_roles.map(&:has_super_admin_permissions?).none? && assigned_acl_ids.present?
          assigned_roles = AccessControl.where(id: assigned_acl_ids).joins(:role).distinct.pluck(Role.arel_table[:id])
          added_role_ids = assigned_roles - existing_roles.pluck(:id)
          Role.where(id: added_role_ids.reject(&:blank?)).find_each do |role|
            # If any role we're adding is administrative, make note, and present the confirmation page
            if role.administrative?
              @admin_role_name = role.role_name
              adming_admin = true
              break
            end
          end
        end
        adming_admin
      end
    end

    private def assigned_acl_ids
      user_params[:access_control_ids]&.reject(&:blank?)&.map(&:to_i) || []
    end

    private def user_scope
      User.active
    end

    private def user_params
      base_params = params[:user] || ActionController::Parameters.new
      base_params.permit(
        :last_name,
        :first_name,
        :email,
        :phone,
        :agency_id,
        :exclude_from_directory,
        :exclude_phone_from_directory,
        :notify_on_new_account,
        :receive_file_upload_notifications,
        :notify_on_vispdat_completed,
        :notify_on_client_added,
        :notify_on_anomaly_identified,
        :receive_account_request_notifications,
        :otp_required_for_login,
        :expired_at,
        :training_completed,
        access_control_ids: [],
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
      )
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
        project_access_groups: [],
        reports: [],
        cohorts: [],
        project_groups: [],
      )
    end

    private def sort_column
      user_scope.column_names.include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    private def sort_direction
      ['asc', 'desc'].include?(params[:direction]) ? params[:direction] : 'asc'
    end

    private def set_user
      @user = User.find(params[:id].to_i)

      @agencies = Agency.order(:name)
    end
  end
end
