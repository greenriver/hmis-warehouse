###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

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

    def has_managed_care(patient) # rubocop:disable Naming/PredicateName
      @inquiry.eligibility_response.managed_care_ids.include? patient.medicaid_id
    end
    helper_method :has_managed_care

    def set_inquiry
      @inquiry = inquiry_scope.select(inquiry_scope.column_names - ['inquiry', 'result']).find(params[:id])
    end

    def inquiry_scope
      Health::EligibilityInquiry.all
    end

    def patient_scope
      Health::Patient.order(:last_name, :first_name)
    end
  end
end
