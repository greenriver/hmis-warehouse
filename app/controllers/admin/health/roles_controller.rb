module Admin::Health
  class RolesController < Admin::RolesController
    include HealthAuthorization
    include HealthPatient
    before_action :require_has_administartive_access_to_health!

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
