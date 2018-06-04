module Admin::Health
  class RolesController < ApplicationController
    before_action :require_can_administer_health!
    
    def index
      # sort / paginate
      @roles = role_scope
        .order(sort_column => sort_direction)
        .page(params[:page]).per(25)
    end
    
    def edit
      @role = role_scope.health.find params[:id]
    end
    
    def update
      @role = Role.health.find params[:id]
      @role.update_attributes role_params
      if @role.save 
        redirect_to({action: :index}, notice: 'Role updated')
      else
        flash[:error] = 'Please review the form problems below'
        render :edit
      end
    end
    
    private
      def role_scope
        Role.health
      end
      def role_params
        params.require(:role).
          permit(
            :name,
            Role.health_permissions
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
