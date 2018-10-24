class IndividualPatientController < HealthController
  before_action :require_some_patient_access!
  after_action :log_client  

end