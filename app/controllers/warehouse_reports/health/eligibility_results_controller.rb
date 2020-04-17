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
      @aco_changes = patient_scope.where(medicaid_id: aco_changes).
        preload(:health_agency, :care_coordinator)
    end

    def has_managed_care(patient) # rubocop:disable Naming/PredicateName
      @inquiry.managed_care_ids.include? patient.medicaid_id
    end
    helper_method :has_managed_care

    def aco_changes
      ids = []
      referral_scope.where(medicaid_id: @inquiry.eligible_ids).each do |referral|
        medicaid_id = referral.medicaid_id
        edi_name = @inquiry.aco_names[medicaid_id]
        if edi_name.present?
          aco_id = Health::AccountableCareOrganization.active.find_by(edi_name: edi_name)&.id
          ids << medicaid_id unless aco_id == referral.accountable_care_organization_id
        end
      end
      ids
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
