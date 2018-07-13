module Window::Health
  class QualifyingActivitiesController < IndividualPatientController
    include PjaxModalController
    include WindowClientPathGenerator
    before_action :require_some_patient_access!
    before_action :set_hpc_patient
    before_action :set_qualifying_activities, only: :index

    def index
      @start_date = params[:start_date]
      @end_date = params[:end_date]
    end

    def set_qualifying_activities
      # search / paginate
      @qualifying_activities = @patient.qualifying_activities
        .date_search(params[:start_date], params[:end_date])
        .order(date_of_activity: :desc)
        .page(params[:page]).per(25)
    end

  end
end
