module Window::Health
  class EpicSsmsController < HealthController
    before_action :require_pilot_or_some_client_access!
    before_action :set_client, only: [:show]
    include PjaxModalController
    include WindowClientPathGenerator
    include HealthFileController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_form, only: [:show]

    def show
      set_hpc_patient
      if @patient.blank?
        set_patient
      end

    end

    def set_form
      @form = form_scope.find(params[:id].to_i)
    end

    def form_scope
      Health::EpicSsm.all
    end
  end
end