###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class HatLoader < BaseLoader
    ENROLLMENT_ID_COL = 'Unique Enrollment Identifier'.freeze
    ASSESSMENT_DATE_COL = 'Date of assessment'.freeze
    RESPONSE_ID_COL = 'Response ID'.freeze

    CDED_FIELD_TYPE_MAP = {
      'total_vulnerability_score' => 'integer',
      'total_housing_rank' => 'integer',
      'apartment_rank' => 'integer',
      'tiny_home_rank' => 'integer',
      'rv_camper_rank' => 'integer',
      'house_rank' => 'integer',
      'mobile_home_rank' => 'integer',
    }.transform_keys { |v| "hat-#{v}" }.freeze

    CDED_REPEATED_TYPE_MAP = {
      'hat-housing_preference' => true,
      'hat-strengths' => true,
      'hat-client_history' => true,
      'hat-housing_placement_challenges' => true,
    }

    CDED_COL_MAP = {
      'Program Name' => 'program_name',
      'Case Number' => 'case_number',
      'Participant Enterprise Identifier' => 'participant_enterprise_identifier',
      'Assessment Type' => 'assessment_type',
      'Assessment Level' => 'assessment_level',
      'Housing Assessment Level' => 'housing_assessment_level',
      'Would you consider living with a roommate ?' => 'consider_living_with_roommate',
      'Housing Preference (Check all that apply.)' => 'housing_preference',
      'Vulnerabilities' => 'vulnerabilities',
      '[STAFF RESPONSE]   Does the client have a disability that is expected to be long-term, and substantially impairs their ability to live independently over time (as indicated in the HUD assessment)?' => 'disability_impairs_independence',
      'Assessment Location' => 'assessment_location',
      'Housing Preference if other' => 'housing_preference_other',
      '[STAFF RESPONSE] Is the client able to work a full-time job?' => 'able_to_work_full_time',
      '[STAFF RESPONSE] Is the client willing to work a full-time?' => 'willing_to_work_full_time',
      'Which housing would not like to live in?' => 'unpreferred_housing',
      'Possible challenges for housing placement options (Check all that apply)' => 'housing_placement_challenges',
      'Has the client had more than 3 hospitalizations or emergency room visits in a year?' => 'more_than_3_hospitalizations',
      'Is the client 60 years old or older?' => 'is_60_or_older',
      'Does the client have cirrhosis of the liver?' => 'has_cirrhosis',
      'Does the client have end stage renal disease?' => 'has_end_stage_renal_disease',
      'Does the client have a history of Heat Stroke?' => 'history_of_heat_stroke',
      'Is the client blind?' => 'is_blind',
      'Does the client have HIV or AIDS?' => 'has_hiv_aids',
      'Does the client have "tri-morbidity" (co-occurring psychiatric, substance abuse, and a chronic medical condition)?' => 'has_tri_morbidity',
      'Is there a high potential for victimization?' => 'high_potential_for_victimization',
      'Is there a danger of self harm or harm to other person in the community?' => 'danger_of_harm',
      'Does the client have a chronic or acute medical condition?' => 'chronic_acute_medical_condition',
      'Does the client have a chronic or acute psychiatric condition with extreme lack of judgement regarding safety?' => 'chronic_acute_psychiatric_condition',
      'Does the client have a chronic or acute substance abuse with extreme lack of judgment regarding safety?' => 'chronic_acute_substance_abuse',
      '[STAFF RESPONSE] Only check this box if you feel the client is unable to live alone due to needing around the clock care or that they may be dangerous/harmful to themselves or their neighbors without ongoing support. (If unknown, you may skip this question.)   Click here for details!' => 'needs_around_the_clock_care',
      '[STAFF RESPONSE]  Explain why this client cannot live independently.' => 'cannot_live_independently_reason',
      '[STAFF RESPONSE] What type of housing intervention would be more suitable for this client, if known?' => 'suitable_housing_intervention',
      'Strengths (Check all that apply.)' => 'strengths',
      'Housing Location Preference (Select ONE or "No Preference" if more than one)' => 'housing_location_preference',
      'Household Type' => 'household_type',
      '[STAFF RESPONSE]  Does the client need site-based case management? (This is NOT skilled nursing, group home, or assisted living care.)' => 'needs_site_based_case_management',
      'Total Vulnerability Score' => 'total_vulnerability_score',
      'Apartment' => 'apartment_rank',
      'Tiny Home' => 'tiny_home_rank',
      'RV/Camper' => 'rv_camper_rank',
      'House' => 'house_rank',
      'Mobile Home/Manufactured Home' => 'mobile_home_rank',
      'Total Housing Rank' => 'total_housing_rank',
      'Client History (Check all that apply):' => 'client_history',
      'Does the client have a preference for neighborhood?' => 'neighborhood_preference',
      'Preferred Neighborhood:' => 'preferred_neighborhood',
      '[CLIENT RESPONSE]  Are you currently working a full time job?' => 'currently_working_full_time',
      '[CLIENT RESPONSE]  If you can work and are willing to work a full time job, why are you not working right now?' => 'not_working_reason',
      '[STAFF RESPONSE]  I believe the client would, more than likely, successfully exit 12-24 month RRH Program and maintain their housing.' => 'likely_rrh_program_success',
      'Client Note' => 'client_note',
      'Is the client a Lifetime Sex Offendor?' => 'client_lifetime_sex_offender',
      'Does the client have a State ID/Drivers License?' => 'client_has_state_id_or_license',
      'Does the client have a Birth Certificate?' => 'client_has_birth_certificate',
      'Does the client have a Social Security Card?' => 'client_has_social_security_card',
      'Do you have a current open case with State Dept. of Family Services (CPS)?' => 'open_case_with_cps',
      'Was in foster care as a youth, at age 16 years or older?' => 'was_in_foster_care_at_16_or_older',
      '[CLIENT RESPONSE] Are you interested in Transitional Housing?' => 'interested_in_transitional_housing',
      '[CLIENT RESPONSE] Can you pass a drug test?' => 'can_pass_drug_test',
      '[CLIENT RESPONSE] Do you have a history of heavy drug use?  (Use that has affected your ability to work and/or maintain housing?)' => 'history_of_heavy_drug_use',
      '[CLIENT RESPONSE]  Have you been clean/sober for at least one year?' => 'clean_sober_for_one_year',
      '[CLIENT RESPONSE] Are you willing to engage with housing case management?  (Would you participate in a program, goal setting, etc.?)' => 'willing_to_engage_with_housing_management',
      '[CLIENT RESPONSE] Have you been employed for 3 months or more?' => 'employed_for_3_months_or_more',
      '[CLIENT RESPONSE] Are you earning $13 an hour or more?' => 'earning_13_dollars_or_more_per_hour',
      '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV).  Are you currently fleeing?' => 'fleeing_due_to_ipv',
      '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV). What was the most recent date the violence occurred? (This can be an estimated date)' => 'most_recent_ipv_incident_date',
      'Do you or have you had (in the past) an I-9 or an ITIN (Individual Tax Identification Number)?' => 'had_i9_or_itin',
      'What was/is your I-9 or ITIN number?' => 'i9_or_itin_number',
      'Age' => 'age',
      'You have indicated your client has had one or more stays in prison/jail/correctional facility in their lifetime.  Did this cause their current episode of homelessness?' => 'incarceration_caused_homelessness',
      'You have indicated your client has had NO earned income from employment during the past year. Did this cause their current episode of homelessness?' => 'lack_of_income_caused_homelessness',
      'You have indicated your client is a survivor of Intimate Partner Violence. Did this cause their current episode of homelessness?' => 'ipv_caused_homelessness',
      'You have indicated your client is a survivor of family violence, sexual violence, or sex trafficking. Did this cause their current episode of homelessness?' => 'violence_survival_caused_homelessness',
      'You have indicated that a household member is living with a chronic health condition that is disabling.  Did this cause their current episode of homelessness?' => 'chronic_health_condition_caused_homelessness',
      'You have indicated that the client has an acute health care need. Did this cause their current episode of homelessness?' => 'acute_health_need_caused_homelessness',
      'You have indicated that the client has an Intellectual/Developmental Disorder (IDD). Did this cause their current episode of homelessness?' => 'idd_caused_homelessness',
      'Are you currently pregnant?' => 'currently_pregnant',
      'If pregnant, is this your first pregnancy AND are you under 28 weeks in the course of the pregnancy?' => 'first_pregnancy_under_28_weeks',
      'Prioritization Status' => 'prioritization_status',
      '[STAFF RESPONSE] Does the client need ongoing housing case management to sustain housing?' => 'needs_ongoing_housing_case_management',
      "How many household members (including minor children) do you expect to live with you when you're housed?" => 'expected_household_members',
      'Are you a single parent with a child over the age of 10?' => 'single_parent_with_child_over_10',
      'Do you have legal custody of your children?' => 'has_legal_custody_of_children',
      'If you do not have legal custody of your children, will you gain custody of the children when you are housed?' => 'gaining_custody_upon_housing',
    }.transform_keys { |k| k.gsub(/\s+/, ' ').strip }.transform_values { |v| v.present? ? "hat-#{v}" : v }

    def perform
      rows = reader.rows(filename: filename)
      clobber_records(rows) if clobber

      create_assessment_records(rows)

      create_cde_definitions

      # relies on custom assessments already built, associated by response_id
      create_cde_records(rows)
    end

    def filename
      'HAT.xlsx'
    end

    def runnable?
      # filename defined in subclass
      super && reader.file_present?(filename)
    end

    protected

    def clobber_records(rows)
      assessment_ids = rows.map do |row|
        row_assessment_id(row)
      end

      scope = model_class.where(data_source_id: data_source.id).where(CustomAssessmentID: assessment_ids)
      scope.preload(:custom_data_elements).find_each do |assessment|
        assessment.custom_data_elements.delete_all # delete should really destroy
        assessment.really_destroy!
      end
    end

    def create_cde_definitions
      CDED_COL_MAP.each_pair do |label, key|
        field_type = CDED_FIELD_TYPE_MAP[key] || :string
        cde_helper.find_or_create_cded(
          owner_type: model_class.sti_name,
          label: label,
          key: key,
          field_type: field_type,
          repeats: CDED_REPEATED_TYPE_MAP[key],
        )
      end
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "hat-eto-#{response_id}"
    end

    def row_assessment_date(row)
      row.field_value(ASSESSMENT_DATE_COL)
    end

    def create_assessment_records(rows)
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment.
        where(data_source: data_source).
        pluck(:enrollment_id, :personal_id).
        to_h

      expected = 0
      actual = 0
      records = rows.flat_map do |row|
        expected += 1
        #enrollment_id = row.field_value(ENROLLMENT_ID_COL)
         enrollment_id = personal_id_by_enrollment_id.keys.first
        personal_id = personal_id_by_enrollment_id[enrollment_id]

        if personal_id.nil?
          log_skipped_row(row, field: ENROLLMENT_ID_COL)
          next # early return
        end
        actual += 1

        {
          data_source_id: data_source.id,
          CustomAssessmentID: row_assessment_id(row),
          EnrollmentID: enrollment_id,
          PersonalID: personal_id,
          UserID: system_hud_user.id,
          AssessmentDate: row_assessment_date(row),
          DataCollectionStage: 2,
          wip: false,
          DateCreated: today,
          DateUpdated: today,
        }
      end
      log_processed_result(expected: expected, actual: actual)
      ar_import(model_class, records)
    end

    def create_cde_records(rows)
      owner_id_by_assessment_id = model_class.where(data_source: data_source).pluck(:CustomAssessmentID, :id).to_h

      cdes = []
      rows.each do |row|
        owner_id = owner_id_by_assessment_id[row_assessment_id(row)]
        raise unless owner_id

        CDED_COL_MAP.each do |col, cded_key|
          value = cde_values(row, col).each do |value|
            cde = cde_helper.new_cde_record(value: value, definition_key: cded_key, owner_type: model_class.sti_name)
            cde[:owner_id] = owner_id
            cdes.push(cde)
          end
        end
      end
      ar_import(Hmis::Hud::CustomDataElement, cdes)
    end

    def cde_values(row, field)
      value = row.field_value(field, required: false)
      return [] unless value

      cded_key = CDED_COL_MAP[field]
      return [value&.to_i] if CDED_FIELD_TYPE_MAP[cded_key] == 'integer'
      if CDED_REPEATED_TYPE_MAP[cded_key]
        return value&.split('|').map(&:strip).compact_blank
      end

      [value]
    end

    def model_class
      Hmis::Hud::CustomAssessment
    end
  end
end
