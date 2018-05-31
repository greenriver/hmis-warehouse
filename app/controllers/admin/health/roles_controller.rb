module Admin::Health
  class RolesController < HealthController
    before_action :require_has_administartive_access_to_health!
    before_action :require_can_administer_health!
    
    def index
      @roles = Role.health
    end
  end
end