###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Health
  class EligibilityResultsController < ApplicationController
    before_action :require_can_administer_health!
    before_action :set_inquiry

    def show
      @eligible = patient_scope.where(medicaid_id: @inquiry.eligible_ids).
        preload(:health_agency, :care_coordinator)
      @ineligible = patient_scope.where(medicaid_id: @inquiry.ineligible_ids).
        preload(:health_agency, :care_coordinator)
      @aco_changes = aco_changes
    end

    def aco_changes
      patient_scope.where(medicaid_id: @inquiry.managed_care_ids).select do |patient|
        (patient.previous_aco_name.present? && patient.previous_aco_name != patient.aco_name) ||
          @inquiry.aco_names[patient.medicaid_id].blank?
      end
    end

    def managed_care?(patient)
      @inquiry.managed_care_ids.include? patient.medicaid_id
    end
    helper_method :managed_care?

    def aco_current?(patient)
      medicaid_id = patient.medicaid_id
      edi_name = @inquiry.aco_names[medicaid_id]
      return false unless edi_name.present?

      aco_id = aco_ids[edi_name]
      aco_id == patient.patient_referral.accountable_care_organization_id
    end
    helper_method :aco_current?

    def aco_ids
      @aco_ids ||= Health::AccountableCareOrganization.active.pluck(:edi_name, :id).to_h
    end

    def set_inquiry
      @inquiry = inquiry_scope.select(inquiry_scope.column_names - ['inquiry', 'result']).find(params[:id].to_i)
    end

    def inquiry_scope
      Health::EligibilityInquiry.where(internal: false)
    end

    def patient_scope
      Health::Patient.order(:last_name, :first_name)
    end

    def referral_scope
      Health::PatientReferral
    end
  end
end
