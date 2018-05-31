module Admin::Health
  class AdminController < HealthController
    before_action :require_has_administartive_access_to_health!


    def index
      
    end

  end
end