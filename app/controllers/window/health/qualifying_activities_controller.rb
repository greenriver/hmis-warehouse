module Window::Health
  class QualifyingActivitiesController < IndividualPatientController
    include PjaxModalController
    include WindowClientPathGenerator
    before_action :require_some_patient_access!
    before_action :set_hpc_patient
    before_action :set_qualifying_activities, only: :index

    def index

    end

    def set_qualifying_activities
      # sort / paginate
      @qualifying_activities = @patient.qualifying_activities
        .order(date_of_activity: :desc)
        .page(params[:page]).per(2)
    end
  end
end
