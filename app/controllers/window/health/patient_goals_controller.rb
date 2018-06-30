module Window::Health
  class PatientGoalsController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient

    include PjaxModalController
    include WindowClientPathGenerator
    include HealthGoal

    def index
      @goals = Health::Goal::Hpc.all
    end

  end
end