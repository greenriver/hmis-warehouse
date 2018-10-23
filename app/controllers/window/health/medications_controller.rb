module Window::Health
  class MedicationsController < HealthController
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
      @medications = @patient.medications.order(start_date: :desc, ordered_date: :desc)

      render layout: !request.xhr?
    end

    protected def title_for_show
      "#{@client.name} - Health - Medications"
    end
  end
end