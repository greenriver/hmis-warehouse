module Window::Health::Careplan
  class PreviousController < HealthController
    include PjaxModalController    

    before_action :require_can_edit_client_health!
    before_action :set_client
    before_action :set_patient
    before_action :set_careplan
    before_action :set_goal

    
    def index

    end
    def show
      @readonly = true
      @version = @goal.versions.find(params[:id].to_i).reify
    end


    def set_careplan
      @careplan = @patient.careplan
    end

    def set_goal
      @goal = Health::Goal::Base.find(params[:goal_id].to_i)
    end
  end
end