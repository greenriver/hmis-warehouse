###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Admin
  class UsersController < ApplicationController
    include ViewableEntities # TODO: START_ACL remove when ACL transition complete
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
        # TODO: START_ACL replace when ACL transition complete
        # preload(:access_controls, :oauth_identities).
        preload(:access_controls, :roles, :oauth_identities).
        # END_ACL
        order(sort_column => sort_direction)

      @pagy, @users = pagy(@users)
    end

    def edit
      @user.set_initial_two_factor_secret!
      @group = @user.access_group # TODO: START_ACL remove when ACL transition complete
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
      return if adding_admin?

      @redirecting = true
      update
      redirect_to({ action: :edit }, notice: 'User updated') and return
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

      existing_health_roles = @user.health_roles.to_a
      begin
        User.transaction do
          @user.skip_reconfirmation!
          # Associations don't play well with acts_as_paranoid, so manually clean up user ACLs
          @user.user_group_members.where.not(user_group_id: assigned_user_group_ids).destroy_all

          # TODO: START_ACL remove when ACL transition complete
          # Associations don't play well with acts_as_paranoid, so manually clean up user roles
          if ! @user.using_acls?
            @user.user_roles.where.not(role_id: user_params[:legacy_role_ids]&.select(&:present?)).destroy_all
            @user.access_groups.not_system.
              where.not(id: user_params[:access_group_ids]&.select(&:present?)).each do |g|
                # Don't remove or add system groups
                next if g.system?

                g.remove(@user)
              end
          end
          # END_ACL
          @user.disable_2fa! if user_params[:otp_required_for_login] == 'false'
          @user.update!(user_params)
          # if we have a user to copy user groups from, add them
          copy_user_groups if @user.using_acls?
          # TODO: START_ACL remove when ACL transition complete
          # Restore any health roles we previously had
          if ! @user.using_acls?
            @user.legacy_roles = (@user.legacy_roles + existing_health_roles).uniq
            @user.set_viewables viewable_params
          end
          # END_ACL
        end
      rescue Exception
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
      end
      # Queue recomputation of external report access
      @user.delay(queue: ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)).populate_external_reporting_permissions!
      respond_with(@user, location: edit_admin_user_path(@user)) unless @redirecting
    end

    private def copy_user_groups
      return unless @user
      return unless user_params[:copy_form_id].present?

      source_user = User.active.not_system.find(user_params[:copy_form_id].to_i)
      return unless source_user

      source_user.user_groups.each do |group|
        group.add(@user)
      end
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
      @adding_admin ||= begin
        adding_admin = false
        # TODO: START_ACL remove when ACL transition complete
        if @user.using_acls?
          existing_roles = @user.roles
          # If we don't already have a role granting an admin permission, and we're assinging some
          # ACLs (with associated roles)
          if existing_roles.map(&:has_super_admin_permissions?).none? && assigned_user_group_ids.present?
            assigned_roles = AccessControl.where(user_group_id: assigned_user_group_ids).joins(:role).distinct.pluck(Role.arel_table[:id])
            added_role_ids = assigned_roles - existing_roles.pluck(:id)
            Role.where(id: added_role_ids.reject(&:blank?)).find_each do |role|
              # If any role we're adding is administrative, make note, and present the confirmation page
              next unless role.administrative?

              @admin_role_name = role.role_name
              adding_admin = true
              break
            end
          end
        else
          existing_roles = @user.legacy_roles
          if existing_roles.map(&:has_super_admin_permissions?).none?
            assigned_roles = user_params[:legacy_role_ids]&.select(&:present?)&.map(&:to_i) || []
            added_role_ids = assigned_roles - existing_roles.pluck(:id)
            added_role_ids.select(&:present?).each do |id|
              role = Role.find(id.to_i)
              next unless role.administrative?

              @admin_role_name = role.role_name
              adding_admin = true
              break
            end
          end
        end
        # END_ACL
        adding_admin
      end
    end

    private def assigned_user_group_ids
      user_params[:user_group_ids]&.reject(&:blank?)&.map(&:to_i) || []
    end

    private def user_scope
      User.active.not_system
    end

    private def user_params
      base_params = params[:user] || ActionController::Parameters.new
      base_params.permit(
        :last_name,
        :first_name,
        :email,
        :talent_lms_email,
        :phone,
        :credentials,
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
        :copy_form_id,
        :permission_context,
        user_group_ids: [],
        superset_roles: [],
        # TODO: START_ACL remove when ACL transition complete
        legacy_role_ids: [],
        access_group_ids: [],
        coc_codes: [],
        # END_ACL
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role],
      ).

        tap do |result|
          # TODO: START_ACL remove when ACL transition complete
          result[:coc_codes] ||= []
          # re-add system groups so we don't remove them here
          result[:access_group_ids] ||= []
          result[:access_group_ids] += @user.access_groups.system.pluck(:id).map(&:to_s)
          # END_ACL

          # User params will never include system user groups in user_group_ids, re-add any of those before saving
          result[:user_group_ids] ||= []
          result[:user_group_ids] += @user.user_groups.system.pluck(:id)
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
