module HealthAuthorization
  extend ActiveSupport::Concern

  included do
    def require_can_review_patient_assignments!
      return true if current_user.can_approve_patient_assignments? || current_user.can_manage_patients_for_own_agency?
      not_authorized!
    end 

    def require_can_manage_health_agencies!
      return true if current_user.can_administer_health? || current_user.can_manage_health_agency?
      not_authorized!
    end

    def require_can_claim_patients!
      if current_user.can_approve_patient_assignments? ||
        current_user.can_manage_all_patients? ||
        current_user.can_manage_patients_for_own_agency?
        return true
      end
      not_authorized!
    end
  end
end