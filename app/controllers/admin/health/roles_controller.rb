module Admin::Health
  class RolesController < Admin::RolesController
    before_action :require_can_administer_health!
    
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
  end
end
