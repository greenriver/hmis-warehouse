module WarehouseReports::Health
  class EligibilityResultsController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_inquiry

    def show
      @eligible = patient_scope.where(medicaid_id: @inquiry.eligibility_response.eligible_ids).
        preload(:health_agency, :care_coordinator)
      @ineligible = patient_scope.where(medicaid_id: @inquiry.eligibility_response.ineligible_ids).
        preload(:health_agency, :care_coordinator)
    end

    def has_managed_care(patient)
      @inquiry.eligibility_response.managed_care_ids.include? patient.medicaid_id
    end
    helper_method :has_managed_care

    def set_inquiry
      @inquiry = inquiry_scope.find(params[:id].to_i)
    end

    def inquiry_scope
      Health::EligibilityInquiry.all
    end

    def patient_scope
      Health::Patient.order(:last_name, :first_name)
    end
  end
end