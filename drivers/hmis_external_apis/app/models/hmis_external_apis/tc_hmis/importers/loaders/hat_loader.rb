###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class HatLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date of assessment'.freeze

    # Gig extracted this from the form definition
    CDED_CONFIGS = [
      { key: 'hat_a6_household_type', label: 'Household Type', repeats: false, field_type: 'string' },
      { key: 'hat_a7_single_parent', label: 'Are you a single parent with a child over the age of 10?', repeats: false, field_type: 'boolean' },
      { key: 'hat_a8_household_size', label: "How many household members (including minor children) do you expect to live with you when you're housed?", repeats: false, field_type: 'integer' },
      { key: 'hat_a9_custody', label: 'Do you have legal custody of your children?', repeats: false, field_type: 'boolean' },
      { key: 'hat_a10_future_custody', label: 'If you do not have legal custody of your children, will you gain custody of the children when you are housed?', repeats: false, field_type: 'boolean' },
      { key: 'hat_a11_unable_to_live_alone', label: 'Client is unable to live alone', repeats: false, field_type: 'boolean' },
      { key: 'hat_a12_unable_to_live_alone_reason', label: '[STAFF RESPONSE] Explain why this client cannot live independently.', repeats: false, field_type: 'string' },
      { key: 'hat_a13_suitable_housing_intervention', label: '[STAFF RESPONSE] What type of housing intervention would be more suitable for this client, if known?', repeats: true, field_type: 'string' },
      { key: 'hat_b1_strength', label: 'Strengths (Check all that apply.)', repeats: true, field_type: 'string' },
      { key: 'hat_b2_challenge', label: 'Possible challenges for housing placement options (Check all that apply)', repeats: true, field_type: 'string' },
      { key: 'hat_b3_lifetime_sex_offendor', label: 'Is the client a Lifetime Sex Offendor?', repeats: false, field_type: 'boolean' },
      { key: 'hat_b4_has_state_id_license', label: 'Does the client have a State ID/Drivers License?', repeats: false, field_type: 'boolean' },
      { key: 'hat_b5_has_birth_certificate', label: 'Does the client have a Birth Certificate?', repeats: false, field_type: 'boolean' },
      { key: 'hat_b6_has_social_security_card', label: 'Does the client have a Social Security Card?', repeats: false, field_type: 'boolean' },
      { key: 'hat_b7_has_i9_itin', label: 'Do you or have you had (in the past) an I-9 or an ITIN (Individual Tax Identification Number)?', repeats: false, field_type: 'boolean' },
      { key: 'hat_b8_i9_itin', label: 'What was/is your I-9 or ITIN number?', repeats: false, field_type: 'string' },
      { key: 'hat_c1_working_full_time', label: '[CLIENT RESPONSE] Are you currently working a full time job?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c2_able_to_work_full_time', label: '[STAFF RESPONSE] Is the client **able** to work a full-time?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c3_willing_to_work_full_time', label: '[STAFF RESPONSE] Is the client **willing** to work a full-time?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c4_reason_not_working_full_time', label: '[CLIENT RESPONSE] If you can work and are willing to work a full time job, why are you not working right now?', repeats: false, field_type: 'string' },
      { key: 'hat_c5_staff_expect_successful_rrh', label: '[STAFF RESPONSE] I believe the client would, more than likely, successfully exit 12-24 month RRH Program and maintain their housing.', repeats: false, field_type: 'boolean' },
      { key: 'hat_c6_client_interested_in_th', label: '[CLIENT RESPONSE] Are you interested in Transitional Housing?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c7_can_pass_drug_test', label: '[CLIENT RESPONSE] Can you pass a drug test?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c8_history_of_drug_use', label: '[CLIENT RESPONSE] Do you have a history of heavy drug use? (Use that has affected your ability to work and/or maintain housing?)', repeats: false, field_type: 'boolean' },
      { key: 'hat_c9_sober_for_one_year', label: '[CLIENT RESPONSE] Have you been clean/sober for at least one year?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c10_willing_to_engage_case_management', label: '[CLIENT RESPONSE] Are you willing to engage with housing case management? (Would you participate in a program, goal setting, etc.?)', repeats: false, field_type: 'boolean' },
      { key: 'hat_c11_employed_at_least_3_months', label: '[CLIENT RESPONSE] Have you been employed for 3 months or more?', repeats: false, field_type: 'boolean' },
      { key: 'hat_c12_earning_at_least_13_hr', label: '[CLIENT RESPONSE] Are you earning $13 an hour or more?', repeats: false, field_type: 'boolean' },
      { key: 'hat_d1_disabling_condition_indefinite_impairs',
        label: '[STAFF RESPONSE] Does the client have a disability that is expected to be long-term, and substantially impairs their ability to live independently over time (as indicated in the HUD assessment)?',
        repeats: false,
        field_type: 'boolean' },
      { key: 'hat_d2_site_based_cm', label: '[STAFF RESPONSE] Does the client need site-based case management? (This is NOT skilled nursing, group home, or assisted living care.)', repeats: false, field_type: 'boolean' },
      { key: 'hat_d3_ongoing_housing_cm', label: '[STAFF RESPONSE] Does the client need ongoing housing case management to sustain housing?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e1_client_history', label: 'Client History (Check all that apply)', repeats: true, field_type: 'string' },
      { key: 'hat_e2_homelessness_cause_jail', label: 'You have indicated your client has had one or more stays in prison/jail/correctional facility in their lifetime. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e3_homelessness_cause_no_employement', label: 'You have indicated your client has had NO earned income from employment during the past year. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e4_homelessness_cause_ipv', label: 'You have indicated your client is a survivor of Intimate Partner Violence. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e5_homelessness_cause_family_violence', label: 'You have indicated your client is a survivor of family violence, sexual violence, or sex trafficking. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e6_homelessness_cause_chronic_health', label: 'You have indicated that a household member is living with a chronic health condition that is disabling. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e7_homelessness_cause_acute_health', label: 'You have indicated that the client has an acute health care need. Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e8_homelessness_cause_idd', label: 'You have indicated that the client has an Intellectual/Developmental Disorder (IDD). Did this cause their current episode of homelessness?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e9_pregnant', label: 'Are you currently pregnant?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e10_first_prefnancy', label: 'If pregnant, is this your first pregnancy AND are you under 28 weeks in the course of the pregnancy?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e11_cps', label: 'Do you have a current open case with State Dept. of Family Services (CPS)?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e12_foster_youth', label: 'Was in foster care as a youth, at age 16 years or older?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e13_ipv_fleeing', label: '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV). Are you currently fleeing?', repeats: false, field_type: 'boolean' },
      { key: 'hat_e14_ipv_date', label: '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV). What was the most recent date the violence occurred? (This can be an estimated date)', repeats: false, field_type: 'date' },
      { key: 'hat_f1_housing_preference', label: 'Housing Preference (Check all that apply)', repeats: true, field_type: 'string' },
      { key: 'hat_f2_other_housing_preference', label: 'Housing Preference if Other', repeats: false, field_type: 'string' },
      { key: 'hat_f3_housing_location_preference', label: "Housing Location Preference (Select ONE or 'No Preference' if more than one)", repeats: false, field_type: 'string' },
      { key: 'hat_f4_housing_neighborhood_preference', label: 'Does the client have a preference for neighborhood?', repeats: false, field_type: 'boolean' },
      { key: 'hat_f5_preferred_neighborhood', label: 'Preferred Neighborhood', repeats: false, field_type: 'string' },
      { key: 'hat_f6_apartment_rank', label: 'Apartment', repeats: false, field_type: 'integer' },
      { key: 'hat_f7_tiny_home_rank', label: 'Tiny Home', repeats: false, field_type: 'integer' },
      { key: 'hat_f8_rv_rank', label: 'RV/Camper', repeats: false, field_type: 'integer' },
      { key: 'hat_f9_house_rank', label: 'House', repeats: false, field_type: 'integer' },
      { key: 'hat_f10_mobile_home_rank', label: 'Mobile Home/Manufactured Home', repeats: false, field_type: 'integer' },
      { key: 'hat_f11_total_housing_rank', label: 'Total Housing Rank', repeats: false, field_type: 'integer' },
      { key: 'hat_f12_client_note', label: 'Client Note', repeats: false, field_type: 'string' },
    ].freeze

    def filename
      'HAT.xlsx'
    end

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "hat-eto-#{response_id}"
    end
  end
end
