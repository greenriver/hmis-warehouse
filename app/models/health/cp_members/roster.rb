###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# ### HIPAA Risk Assessment
# Risk: Relates to a patient and contains PHI
# Control: PHI attributes documented
module Health
  class CpMembers::Roster < HealthBase
    belongs_to :roster_file, class_name: 'Health::CpMembers::RosterFile', optional: true

    phi_attr :member_id, Phi::HealthPlan, "ID of CP member"
    phi_attr :nam_first, Phi::Name, "First name of member"
    phi_attr :nam_last, Phi::Name, "Last name of member"
    phi_attr :cp_pidsl, Phi::SmallPopulation
    phi_attr :cp_name, Phi::SmallPopulation
    phi_attr :aco_pidsl, Phi::SmallPopulation
    phi_attr :aco_name, Phi::SmallPopulation
    phi_attr :mco_pidsl, Phi::SmallPopulation
    phi_attr :mco_name, Phi::SmallPopulation
    # :sex # gender is not HIPAA protected information
    phi_attr :date_of_birth, Phi::Date, "Date of birth of member"
    phi_attr :mailing_address_1, Phi::Location, "First line of mailing address"
    phi_attr :mailing_address_2, Phi::Location, "Second line of mailing address"
    phi_attr :mailing_city, Phi::Location, "City of mailing address"
    phi_attr :mailing_state, Phi::Location, "State of mailing address"
    phi_attr :mailing_zip, Phi::Location, "Zip code of mailing address"
    phi_attr :residential_address_1, Phi::Location, "First line of residential address"
    phi_attr :residential_address_2, Phi::Location, "Second line of residential address"
    phi_attr :residential_city, Phi::Location, "City of residential address"
    phi_attr :residential_state, Phi::Location, "State of residential address"
    phi_attr :residential_zip, Phi::Location, "Zip code of residential address"
    phi_attr :race, Phi::SmallPopulation, "Race of member"
    phi_attr :phone_number, Phi::Telephone, "Phone number of member"
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
    phi_attr :last_office_visit, Phi::Date, "Date of last office visit"
    phi_attr :last_ed_visit, Phi::Date, "Date of last emergency department (ED) visit"
    phi_attr :last_ip_visit, Phi::Date, "Date of last inpatient hospital treatment (IP) visit"
    phi_attr :enrolled_flag, Phi::SmallPopulation
    phi_attr :enrollment_status, Phi::SmallPopulation, "Status of enrollment"
    phi_attr :cp_claim_dt, Phi::Date, "Date of CP claim"
    phi_attr :qualifying_hcpcs, Phi::SmallPopulation
    phi_attr :qualifying_hcpcs_nm, Phi::SmallPopulation
    phi_attr :qualifying_dsc, Phi::SmallPopulation
    phi_attr :email, Phi::Email, "Email of member"
    phi_attr :head_of_household, Phi::Name, "Name of member's head of household"

    alias_attribute :first_name, :nam_first
    alias_attribute :last_name, :nam_last
  end
end
