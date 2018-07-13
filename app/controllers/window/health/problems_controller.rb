module Window::Health
  class ProblemsController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    before_action :require_pilot_or_some_client_access!

    before_action :set_client, only: [:index]
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      set_hpc_patient
      if @patient.blank?
        set_patient
      end
      @problems = @patient.problems.order(onset_date: :desc)

      render layout: !request.xhr?
    end

  end
end