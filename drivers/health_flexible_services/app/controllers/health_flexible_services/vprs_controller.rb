###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HealthFlexibleServices
  class VprsController < IndividualPatientController
    include AjaxModalRails::Controller
    include ArelHelper
    include ClientPathGenerator
    before_action :set_client
    before_action :set_hpc_patient

    def index
      @vprs = @patient # .flexible_services
      @follow_ups = @patient # .flexible_service_follow_ups
    end

    def new
      @vpr = vpr_source.new(user: current_user, patient: @patient).set_defaults
    end

    private def vpr_source
      HealthFlexibleServices::Vpr
    end

    private def vpr_scope
      vpr_source.order(created_at: :desc)
    end

    private def permitted_params
      attrs = [
        :planned_on,
        :first_name,
        :middle_name,
        :last_name,
        :dob,
        :accommodations_needed,
        :contact_type,
        :phone,
        :email,
        :additional_contact_details,
        :main_contact_first_name,
        :main_contact_last_name,
        :main_contact_organization,
        :main_contact_phone,
        :main_contact_email,
        :reviewer_first_name,
        :reviewer_last_name,
        :reviewer_organization,
        :reviewer_phone,
        :reviewer_email,
        :representative_first_name,
        :representative_last_name,
        :representative_organization,
        :representative_phone,
        :representative_email,
        :member_agrees_to_plan,
        :member_agreement_notes,
        :aco_approved,
        :aco_approved_on,
        :aco_rejection_notes,
        :health_needs_screened_on,
        :complex_physical_health_need,
        :complex_physical_health_need_detail,
        :behavioral_health_need,
        :behavioral_health_need_detail,
        :activities_of_daily_living,
        :activities_of_daily_living_detail,
        :ed_utilization,
        :ed_utilization_detail,
        :high_risk_pregnancy,
        :high_risk_pregnancy_detail,
        :risk_factors_screened_on,
        :experiencing_homelessness,
        :experiencing_homelessness_detail,
        :at_risk_of_homelessness,
        :at_risk_of_homelessness_detail,
        :at_risk_of_nutritional_deficiency,
        :at_risk_of_nutritional_deficiency_detail,
        :health_and_risk_notes,
        :receives_snap,
        :receives_wic,
        :receives_csp,
        :receives_other,
        :receives_other_detail,
        :gender,
        :gender_detail,
        :sexual_orientation,
        :sexual_orientation_detail,
        :race,
        :race_detail,
        :primary_language,
        :education,
        :education_detail,
        :employment_status,
      ]
      attrs += vpr_source.service_attributes
      params.require(:vpr).permit(attrs)
    end
  end
end
