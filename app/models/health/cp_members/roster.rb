###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# ### HIPPA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class CpMembers::Roster < HealthBase
    belongs_to :roster_file, class_name: 'Health::CpMembers::RosterFile'

    phi_attr :member_id, Phi::HealthPlan
    phi_attr :nam_first, Phi::Name
    phi_attr :nam_last, Phi::Name
    phi_attr :cp_pidsl, Phi::SmallPopulation
    phi_attr :cp_name, Phi::SmallPopulation
    phi_attr :aco_pidsl, Phi::SmallPopulation
    phi_attr :aco_name, Phi::SmallPopulation
    phi_attr :mco_pidsl, Phi::SmallPopulation
    phi_attr :mco_name, Phi::SmallPopulation
    # :sex # gender is not HIPAA protected information
    phi_attr :date_of_birth, Phi::Date
    phi_attr :mailing_address_1, Phi::Location
    phi_attr :mailing_address_2, Phi::Location
    phi_attr :mailing_city, Phi::Location
    phi_attr :mailing_state, Phi::Location
    phi_attr :mailing_zip, Phi::Location
    phi_attr :residential_address_1, Phi::Location
    phi_attr :residential_address_2, Phi::Location
    phi_attr :residential_city, Phi::Location
    phi_attr :residential_state, Phi::Location
    phi_attr :residential_zip, Phi::Location
    phi_attr :race, Phi::SmallPopulation
    phi_attr :phone_number, Phi::Telephone
    phi_attr :primary_language_s, Phi::SmallPopulation
    phi_attr :primary_language_w, Phi::SmallPopulation
    phi_attr :sdh_nss7_score, Phi::NeedsReview
    phi_attr :sdh_homelessness, Phi::NeedsReview
    phi_attr :sdh_addresses_flag, Phi::NeedsReview
    phi_attr :sdh_other_disabled, Phi::NeedsReview
    phi_attr :sdh_spmi, Phi::NeedsReview
    phi_attr :raw_risk_score, Phi::NeedsReview
    phi_attr :normalized_risk_score, Phi::NeedsReview
    phi_attr :raw_dxcg_risk_score, Phi::NeedsReview
    phi_attr :last_office_visit, Phi::Date
    phi_attr :last_ed_visit, Phi::Date
    phi_attr :last_ip_visit, Phi::Date
    phi_attr :enrolled_flag, Phi::SmallPopulation
    phi_attr :enrollment_status, Phi::SmallPopulation
    phi_attr :cp_claim_dt, Phi::Date
    phi_attr :qualifying_hcpcs, Phi::SmallPopulation
    phi_attr :qualifying_hcpcs_nm, Phi::SmallPopulation
    phi_attr :qualifying_dsc, Phi::SmallPopulation
    phi_attr :email, Phi::Email
    phi_attr :head_of_household, Phi::Name

    alias_attribute :first_name, :nam_first
    alias_attribute :last_name, :nam_last
  end
end