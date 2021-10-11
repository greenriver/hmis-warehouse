###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class MemberStatusReportPatient < HealthBase
    acts_as_paranoid

    phi_patient :medicaid_id
    phi_attr :member_status_report_id, Phi::SmallPopulation
    phi_attr :medicaid_id, Phi::HealthPlan
    phi_attr :member_first_name, Phi::Name
    phi_attr :member_last_name, Phi::Name
    phi_attr :member_middle_initial, Phi::Name
    phi_attr :member_suffix, Phi::Name
    phi_attr :member_date_of_birth, Phi::Date
    # phi_attr :member_sex
    # phi_attr :aco_mco_name, Phi::SmallPopulation
    # phi_attr :aco_mco_pid, Phi::SmallPopulation
    # phi_attr :aco_mco_sl, Phi::SmallPopulation
    # phi_attr :cp_name_official, Phi::SmallPopulation
    # phi_attr :cp_pid, Phi::SmallPopulation
    # phi_attr :cp_sl, Phi::SmallPopulation
    # phi_attr :cp_outreach_status
    phi_attr :cp_last_contact_date, Phi::Date
    # phi_attr :cp_last_contact_face
    phi_attr :cp_contact_face, Phi::NeedsReview
    phi_attr :cp_participation_form_date, Phi::Date
    phi_attr :cp_care_plan_sent_pcp_date, Phi::Date
    phi_attr :cp_care_plan_returned_pcp_date, Phi::Date
    phi_attr :key_contact_name_first, Phi::Name # Phi::NeedsReview?
    phi_attr :key_contact_name_last, Phi::Name # Phi::NeedsReview?
    phi_attr :key_contact_phone, Phi::Telephone # Phi::NeedsReview?
    phi_attr :key_contact_email, Phi::Email # Phi::NeedsReview?
    phi_attr :care_coordinator_first_name, Phi::Name # Phi::NeedsReview?
    phi_attr :care_coordinator_last_name, Phi::Name # Phi::NeedsReview?
    phi_attr :care_coordinator_phone, Phi::Telephone # Phi::NeedsReview?
    phi_attr :care_coordinator_email, Phi::Email # Phi::NeedsReview?
    # phi_attr :record_status
    phi_attr :record_update_date, Phi::Date # Phi::NeedsReview?
    phi_attr :export_date, Phi::Date # Phi::NeedsReview?


    belongs_to :member_status_report, optional: true
    has_one :patient, primary_key: :medicaid_id, foreign_key: :medicaid_id
    has_one :patient_referral, through: :patient

  end
end
