module Admin
  class UsersController < ApplicationController
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
    end

    def edit
      @user = user_scope.find(params[:id].to_i)
    end

    def update
      @user = user_scope.find(params[:id].to_i)
      existing_health_roles = @user.roles.health.to_a
      begin
        User.transaction do
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
      @user.destroy
      redirect_to({action: :index}, notice: 'User deleted')
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

    private def user_scope
      User
    end

    private def user_params
      params.require(:user).permit(
        :last_name,
        :first_name,
        :email,
        role_ids: [],
        contact_attributes: [:id, :first_name, :last_name, :phone, :email, :role]
      )
    end

    private def viewable_params
      params.require(:user).permit(
        data_sources: [],
        organizations: [],
        projects: []
      )
    end

    private def sort_column
      user_scope.column_names.include?(params[:sort]) ? params[:sort] : 'last_name'
    end

    private def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    private def log_user
      log_item(@user) if @user.present?
    end
  end
end
