module Admin
  class UsersController < ApplicationController
    include ViewableEntities
    # This controller is namespaced to prevent
    # route collision with Devise
    before_action :require_can_edit_users!
    after_action :log_user, only: [:show, :edit, :update, :destroy]
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

      # sort / paginate
      @users = @users
        .order(sort_column => sort_direction)
        .page(params[:page]).per(25)
      @inactive_users = User.inactive
    end

    def edit
      @user = user_scope.find(params[:id].to_i)
    end

    def confirm
      @user = user_scope.find(params[:id].to_i)
      if ! adding_admin?
        update
      end
    end

    def update
      @user = user_scope.find(params[:id].to_i)
      if adding_admin?
        if ! current_user.valid_password?(user_params[:password])
          flash[:error] = "User not updated. Incorrect password"
          render :confirm
          return
        end
      end
      existing_health_roles = @user.roles.health.to_a
      begin
        User.transaction do
          @user.skip_reconfirmation!
          # Associations don't play well with acts_as_paranoid, so manually clean up user roles
          @user.user_roles.where.not(role_id: user_params[:role_ids]&.select(&:present?)).destroy_all
          @user.update(user_params)

          # Restore any health roles we previously had
          @user.roles = (@user.roles + existing_health_roles).uniq
          @user.set_viewables viewable_params
        end
     rescue Exception => e
        flash[:error] = 'Please review the form problems below'
        render :edit
        return
     end
      redirect_to({action: :index}, notice: 'User updated')
    end

    def destroy
      @user = user_scope.find params[:id]
      @user.update(active: false)
      redirect_to({action: :index}, notice: 'User deactivated')
    end

    def title_for_show
      @user.name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show

    def title_for_index
      'User List'
    end

    private def adding_admin?
      existing_roles = @user.user_roles
      existing_roles.each do |role|
        # User is already an admin, so we aren't adding anything
        return false if role.administrative?
      end

      assigned_roles = user_params[:role_ids] || []
      added_role_ids = assigned_roles - existing_roles.pluck(:role_id)
      added_role_ids.reject { |id| id.empty? }.each do |id|
        role = Role.find(id.to_i)
        if role.administrative?
          @admin_role_name = role.role_name
          return true
        end
      end
      false
    end
    helper_method :adding_admin?

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
        :agency,
        :receive_file_upload_notifications,
        :notify_on_vispdat_completed,
        :notify_on_client_added,
        :notify_on_anomaly_identified,
        :password,
        role_ids: [],
        coc_codes: [],
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role]
      ).tap do |result|
        result[:coc_codes] ||= []
      end
    end

    private def viewable_params
      params.require(:user).permit(
        data_sources: [],
        organizations: [],
        projects: [],
        reports: [],
        cohorts: []
      )
    end

    private def sort_column
      user_scope.column_names.include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

  end
end
