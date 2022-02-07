###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class CpMembers::EnrollmentRoster < HealthBase
    belongs_to :roster_file, class_name: 'Health::CpMembers::EnrollmentRosterFile', optional: true

    phi_attr :member_id, Phi::HealthPlan
    phi_attr :performance_year, Phi::SmallPopulation
    phi_attr :region, Phi::Location
    phi_attr :service_area, Phi::Location
    phi_attr :aco_pidsl, Phi::SmallPopulation
    phi_attr :aco_name, Phi::SmallPopulation
    phi_attr :pcc_pidsl, Phi::SmallPopulation
    phi_attr :pcc_name, Phi::SmallPopulation
    phi_attr :pcc_npi, Phi::SmallPopulation
    phi_attr :pcc_taxid, Phi::SmallPopulation
    phi_attr :mco_pidsl, Phi::SmallPopulation
    phi_attr :mco_name, Phi::SmallPopulation
    phi_attr :enrolled_flag, Phi::NeedsReview
    phi_attr :enroll_type, Phi::SmallPopulation
    phi_attr :enroll_stop_reason, Phi::SmallPopulation
    phi_attr :rating_category_char_cd, Phi::SmallPopulation
    phi_attr :ind_dds, Phi::SmallPopulation
    phi_attr :ind_dmh, Phi::SmallPopulation
    phi_attr :ind_dta, Phi::SmallPopulation
    phi_attr :ind_dss, Phi::SmallPopulation
    phi_attr :cde_hcb_waiver, Phi::SmallPopulation
    phi_attr :cde_waiver_category, Phi::SmallPopulation
    phi_attr :span_start_date, Phi::Date
    phi_attr :span_end_date, Phi::Date
    phi_attr :span_mem_days, Phi::SmallPopulation
    phi_attr :cp_prov_type, Phi::SmallPopulation
    phi_attr :cp_plan_type, Phi::SmallPopulation
    phi_attr :cp_pidsl, Phi::SmallPopulation
    phi_attr :cp_prov_name, Phi::SmallPopulation
    phi_attr :cp_enroll_dt, Phi::Date
    phi_attr :cp_disenroll_dt, Phi::Date
    phi_attr :cp_start_rsn, Phi::SmallPopulation
    phi_attr :cp_stop_rsn, Phi::SmallPopulation
    phi_attr :ind_medicare_a, Phi::NeedsReview
    phi_attr :ind_medicare_b, Phi::NeedsReview
    phi_attr :tpl_coverage_cat, Phi::SmallPopulation
  end
end
