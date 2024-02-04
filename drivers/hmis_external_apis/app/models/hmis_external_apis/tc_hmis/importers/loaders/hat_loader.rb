###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class HatLoader < BaseLoader
    def filename
      'HAT.xlsx'
    end

    def perform
      rows = reader.rows(filename: filename)
      clobber_records(rows) if clobber

      assessment_records = build_assessment_records(rows)
      ar_import(Hmis::Hud::CustomAssessment, assessment_records)

      create_cde_definitions

      # relies on custom assessments already built, associated by response_id
      cde_records = build_cde_records(rows)
      ar_import(Hmis::Hud::CustomDataElement, cde_records)
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

      scope = Hmis::Hud::CustomAssessment.
        where(data_source_id: data_source.id).
        where(CustomAssessmentID: assessment_ids)
      scope.preload(:custom_data_elements).find_each do |assessment|
        assessment.custom_data_elements.delete_all # delete should really destroy
        assessment.really_destroy!
      end
    end

    def create_cde_definitions
      CDED_COL_MAP.each_pair do |label, key|
        field_type = CDED_FIELD_TYPE_MAP[key] || :string
        cde_helper.find_or_create_cded(
          owner_type: Hmis::Hud::CustomAssessment.sti_name,
          label: label,
          key: key,
          field_type: field_type,
        )
      end
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "spdat-eto-#{response_id}"
    end

    def row_assessment_date(row)
      row.field_value(ASSESSMENT_DATE_COL)
    end

    ENROLLMENT_ID_COL = 'Unique Enrollment Identifier'.freeze
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze
    RESPONSE_ID_COL = 'Response ID'.freeze

    CDED_FIELD_TYPE_MAP = {
      'travel_time_minutes' => 'integer',
      'time_spent_minutes' => 'integer',
      'total_score' => 'integer',
      'assessment_absent_days' => 'integer',
    }.freeze
    CDED_COL_MAP = {
      'Program Name' => 'program_name',
      'Case Number' => 'case_number',
      'Participant Enterprise Identifier' => 'participant_enterprise_identifier',
      ####
      'Assessment Type' => '',
      'Assessment Level' => '',
      'Housing Assessment Level' => '',
      'Would you consider living with a roommate ?' => '',
      'Housing Preference (Check all that apply.)' => '',
      'Vulnerabilities' => '',
      '[STAFF RESPONSE]   Does the client have a disability that is expected to be long-term, and substantially impairs their ability to live independently over time (as indicated in the HUD assessment)?' => '',
      'Assessment Location' => '',
      'Housing Preference if other' => '',
      'Date of assessment' => '',
      '[STAFF RESPONSE] Is the client able to work a full-time job?' => '',
      '[STAFF RESPONSE] Is the client willing to work a full-time?' => '',
      'Which housing would not like to live in?' => '',
      'Possible challenges for housing placement options (Check all that apply)' => '',
      'Has the client had more than 3 hospitalizations or emergency room visits in a year?' => '',
      'Is the client 60 years old or older?' => '',
      'Does the client have cirrhosis of the liver?' => '',
      'Does the client have end stage renal disease?' => '',
      'Does the client have a history of Heat Stroke?' => '',
      'Is the client blind?' => '',
      'Does the client have HIV or AIDS?' => '',
      'Does the client have "tri-morbidity" (co-occurring psychiatric, substance abuse, and a chronic medical condition)?' => '',
      'Is there a high potential for victimization?' => '',
      'Is there a danger of self harm or harm to other person in the community?' => '',
      'Does the client have a chronic or acute medical condition?' => '',
      'Does the client have a chronic or acute psychiatric condition with extreme lack of judgement regarding safety?' => '',
      'Does the client have a chronic or acute substance abuse with extreme lack of judgment regarding safety?' => '',
      '[STAFF RESPONSE] Only check this box if you feel the client is unable to live alone due to needing around the clock care or that they may be dangerous/harmful to themselves or their neighbors without ongoing support. (If unknown, you may skip this question.)   Click here for details!' => '',
      '[STAFF RESPONSE]  Explain why this client cannot live independently.' => '',
      '[STAFF RESPONSE] What type of housing intervention would be more suitable for this client, if known?' => '',
      'Strengths (Check all that apply.)' => '',
      'Housing Location Preference (Select ONE or "No Preference" if more than one)' => '',
      'Household Type' => '',
      '[STAFF RESPONSE]  Does the client need site-based case management? (This is NOT skilled nursing, group home, or assisted living care.)' => '',
      'Total Vulnerability Score' => '',
      'Apartment' => '',
      'Tiny Home' => '',
      'RV/Camper' => '',
      'House' => '',
      'Total Housing Rank' => '',
      'Client History (Check all that apply):' => '',
      'Does the client have a preference for neighborhood?' => '',
      'Preferred Neighborhood:' => '',
      '[CLIENT RESPONSE]  Are you currently working a full time job?' => '',
      '[CLIENT RESPONSE]  If you can work and are willing to work a full time job, why are you not working right now?' => '',
      '[STAFF RESPONSE]  I believe the client would, more than likely, successfully exit 12-24 month RRH Program and maintain their housing.' => '',
      'Client Note' => '',
      'Mobile Home/Manufactured Home' => '',
      'Is the client a Lifetime Sex Offendor?' => '',
      'Does the client have a State ID/Drivers License?' => '',
      'Does the client have a Birth Certificate?' => '',
      'Does the client have a Social Security Card?' => '',
      'Do you have a current open case with State Dept. of Family Services (CPS)?' => '',
      'Was in foster care as a youth, at age 16 years or older?' => '',
      '[CLIENT RESPONSE] Are you interested in Transitional Housing?' => '',
      '[CLIENT RESPONSE] Can you pass a drug test?' => '',
      '[CLIENT RESPONSE] Do you have a history of heavy drug use?  (Use that has affected your ability to work and/or maintain housing?)' => '',
      '[CLIENT RESPONSE]  Have you been clean/sober for at least one year?' => '',
      '[CLIENT RESPONSE] Are you willing to engage with housing case management?  (Would you participate in a program, goal setting, etc.?)' => '',
      '[CLIENT RESPONSE] Have you been employed for 3 months or more?' => '',
      '[CLIENT RESPONSE] Are you earning $13 an hour or more?' => '',
      '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV).  Are you currently fleeing?' => '',
      '[CLIENT RESPONSE] You indicated a history of Intimate Partner Violence (IPV). What was the most recent date the violence occurred? (This can be an estimated date)' => '',
      'Do you or have you had (in the past) an I-9 or an ITIN (Individual Tax Identification Number)?' => '',
      'What was/is your I-9 or ITIN number?' => '',
      'Age' => '',
      'You have indicated your client has had one or more stays in prison/jail/correctional facility in their lifetime.  Did this cause their current episode of homelessness?' => '',
      'You have indicated your client has had NO earned income from employment during the past year. Did this cause their current episode of homelessness?' => '',
      'You have indicated your client is a survivor of Intimate Partner Violence. Did this cause their current episode of homelessness?' => '',
      'You have indicated your client is a survivor of family violence, sexual violence, or sex trafficking. Did this cause their current episode of homelessness?' => '',
      'You have indicated that a household member is living with a chronic health condition that is disabling.  Did this cause their current episode of homelessness?' => '',
      'You have indicated that the client has an acute health care need. Did this cause their current episode of homelessness?' => '',
      'You have indicated that the client has an Intellectual/Developmental Disorder (IDD). Did this cause their current episode of homelessness?' => '',
      'Are you currently pregnant?' => '',
      'If pregnant, is this your first pregnancy AND are you under 28 weeks in the course of the pregnancy?' => '',
      'Prioritization Status' => '',
      '[STAFF RESPONSE] Does the client need ongoing housing case management to sustain housing?' => '',
      "How many household members (including minor children) do you expect to live with you when you're housed?" => '',
      'Are you a single parent with a child over the age of 10?' => '',
      'Do you have legal custody of your children?' => '',
      'If you do not have legal custody of your children, will you gain custody of the children when you are housed?' => '',
    }.transform_values { |v| "hat-#{v}" }

    def build_assessment_records(rows)
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment.
        where(data_source: data_source).
        pluck(:enrollment_id, :personal_id).
        to_h

      expected = 0
      actual = 0
      records = rows.flat_map do |row|
        expected += 1
        enrollment_id = row.field_value(ENROLLMENT_ID_COL)
        personal_id = personal_id_by_enrollment_id[enrollment_id]

        if personal_id.nil?
          log_skipped_row(row, field: ENROLLMENT_ID_COL)
          next # early return
        end
        actual += 1

        Hmis::Hud::CustomAssessment.new(
          data_source_id: data_source.id,
          CustomAssessmentID: row_assessment_id(row),
          enrollment_id: enrollment_id,
          personal_id: personal_id,
          user_id: system_hud_user.id,
          assessment_date: row_assessment_date(row),
          DataCollectionStage: 2,
          wip: false,
        )
      end
      log_processed_result(expected: expected, actual: actual)
      records
    end

    def build_cde_records(rows)
      owner_id_by_assessment_id = Hmis::Hud::CustomAssessment.
        where(data_source: data_source).
        pluck(:CustomAssessmentID, :id).
        to_h

      cdes = []
      records = rows.each do |row|
        owner_id = owner_id_by_assessment_id[row_assessment_id(row)]
        raise unless owner_id

        CDED_COL_MAP.each do |score_col, cded_key|
          value = transform_value(row, score_col)
          next unless value

          cde = new_cde_record(value: value, definition_key: cded_key)
          cde[:owner_id] = owner_id
          cdes.push(cde)
        end
      end
      log_processed_result(expected: expected, actual: actual)
      records
    end

    def transform_value(row, field)
      value = row.field_value(field)
      case CDED_COL_MAP[field]
      when 'total_score'
        value.to_i
      when cded_key =~ /_score$/
        return value unless value

        # score choice values start with integer which is the score
        raise "unexpected value #{value} for #{row.inspect}" unless value =~ /^[0-9].*/

        score = value&.to_i
        value = "#{cded_key}-#{score}"
      end
    end

    def model_class
      Hmis::Hud::CustomAssessment
    end
  end
end
