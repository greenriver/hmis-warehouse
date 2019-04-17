module WarehouseReports::Health
  class EligibilityResultsController < ApplicationController
    before_action :require_can_administer_health!

    def show
      @inquiry = inquiry_scope.find(params[:id].to_i)
      @eligible = patient_scope.where(medicaid_id: @inquiry.eligibility_response.eligible_ids)
      @ineligible = patient_scope.where(medicaid_id: @inquiry.eligibility_response.ineligible_ids)
    end

    def inquiry_scope
      Health::EligibilityInquiry
    end

    def patient_scope
      Health::Patient.order(:last_name, :first_name)
    end
  end
end