module Health
  class PatientsController < HealthController
    before_action :require_can_view_patients_for_own_agency!
    before_action :require_user_has_health_agency!
    before_action :set_patients
    include ClientPathGenerator

    def index

    end
    

    def set_patients
      @patients = patient_source.joins(:health_agency).where(agencies: {id: current_user.health_agency.id})
    end
    
    def patient_source
      Health::Patient
    end

    def require_user_has_health_agency!
      return true if current_user.health_agency.present?
      not_authorized!
    end
  end
end