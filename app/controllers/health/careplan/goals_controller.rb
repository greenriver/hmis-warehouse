module Health
  class Careplan::GoalsController < ::Window::Health::Careplan::GoalsController
    include ClientPathGenerator
    
    def create_success_path 
      client_health_careplan_path(client_id: @client.id)
    end

  end
end