module Window::Health
  class UtilizationController < HealthController
    # This controller serves both BH CP data and pilot data, so it can't use the BH CP permissions
    before_action :require_pilot_or_some_client_access!

    include PjaxModalController
    include WindowClientPathGenerator

    def index
      set_hpc_patient
      if @patient.blank?
        set_patient
      end
      @visits = @patient.visits.order(date_of_service: :desc)

      render layout: !request.xhr?
    end

    protected def title_for_show
      "#{@client.name} - Health - Utilization"
    end
  end
end