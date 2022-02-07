###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthAuthorization
  extend ActiveSupport::Concern

  included do
    def require_has_administrative_access_to_health!
      return true if current_user.has_administrative_access_to_health?

      not_authorized!
    end

    def require_can_review_patient_assignments!
      return true if current_user.has_patient_referral_review_access?

      not_authorized!
    end

    def require_can_manage_health_agencies!
      return true if current_user.can_administer_health? || current_user.can_manage_health_agency?

      not_authorized!
    end

    def require_can_claim_patients!
      if current_user.can_approve_patient_assignments? ||
        current_user.can_manage_all_patients? ||
        current_user.can_manage_health_agency?
        return true
      end

      not_authorized!
    end

    def require_some_patient_access!
      return true if GrdaWarehouse::Config.get(:healthcare_available) && current_user.has_some_patient_access?

      not_authorized!
    end

    def require_pilot_or_some_client_access!
      return true if current_user.has_some_patient_access? || current_user.can_edit_client_health? || current_user.can_view_client_health?

      not_authorized!
    end
  end
end
