module Admin
  class RolesController < ApplicationController
    before_action :require_can_edit_roles!
    helper_method :sort_column, :sort_direction
    require 'active_support'
    require 'active_support/core_ext/string/inflections'

    def index
      # sort / paginate
      @roles = role_scope
        .order(sort_column => sort_direction)
        .page(params[:page]).per(25)
    end

    def new
      @role = Role.new
    end

    def edit
      @role = role_scope.find params[:id]
    end

    def update
      @role = role_scope.find params[:id]
      @role.update_attributes role_params
      if @role.save 
        redirect_to({action: :index}, notice: 'Role updated')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def create
      @role = Role.new(role_params)
      if @role.save 
        redirect_to({action: :index}, notice: 'Role created')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end

    def destroy
      @role = role_scope.find params[:id]
      @role.destroy
      redirect_to({action: :index}, notice: 'Role deleted')
    end

    def title_for_show
      @role.name
    end
    alias_method :title_for_edit, :title_for_show
    alias_method :title_for_destroy, :title_for_show
    alias_method :title_for_update, :title_for_show

    def title_for_index
      'Role List'
    end

    private
      def role_scope
        Role.editable
      end

      def role_params
        params.require(:role).
          permit(
            :name,
            Role.permissions(exclude_health: true)
          )
      end
      def sort_column
        role_scope.column_names.include?(params[:sort]) ? params[:sort] : 'name'
      end

      def sort_direction
        %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
      end
  end

end
