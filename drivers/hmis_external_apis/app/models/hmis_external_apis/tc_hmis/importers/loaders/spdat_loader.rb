###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class SpdatLoader < BaseLoader
    def filename
      'SPDAT.xlsx'
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
          field_type: field_type
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

    ENROLLMENT_ID_COL = "Unique Enrollment Identifier"
    ASSESSMENT_DATE_COL = "Date Taken"
    RESPONSE_ID_COL = "Response ID"

    CDED_FIELD_TYPE_MAP = {
      "travel_time_minutes" => 'integer',
      "time_spent_minutes" => 'integer',
      "total_score" => 'integer',
      "assessment_absent_days" => 'integer',
    }
    CDED_COL_MAP = {
      "Program Name" => "program_name",
      "Case Number" => "case_number",
      "Participant Enterprise Identifier" => "participant_enterprise_identifier",
      "Which SPDAT is this?" => "assessment_event",
      "Travel Time" => "travel_time_minutes",
      "Time Spent" => "time_spent_minutes",
      "Contact Location / Method" => "client_contact_location_and_method",
      "SPDAT Score" => "total_score",
      "SPDAT Notes" => "score_notes",
      "Is this assessment being completed for a dismissed client or a client who is no longer in contact?" => 'spdat-assessment_is_for_absent_client',
      "How long has the client been out of contact (in days)?" => "assessment_absent_days",
      "Mental Health & Wellness & Cognitive Functioning Scoring" => 'mental_health_score',
      "Mental Health & Wellness & Cognitive Functioning Notes:" => 'mental_health_notes',
      "Physical Health & Wellness Scoring" => 'physical_health_score',
      "Physical Health & Wellness Notes:" => 'physical_health_notes',
      "Medication Scoring" => 'medication_score',
      "Medication Notes:" => 'medication_notes',
      "Substance Use Scoring" => 'substance_use_score',
      "Substance Use Notes:" => 'substance_use_notes',
      "Experience of Abuse & Trauma Scoring" => 'abuse_and_trauma_score',
      "Experience of Abuse & Trauma Notes:" => 'abuse_and_trauma_notes',
      "Risk of Harm to Self or Others Scoring" => 'risk_of_harm_score',
      "Risk of Harm to Self or Others Notes:" => 'risk_of_harm_notes',
      "Involvement in Higher Risk and/or Exploitive Situations Scoring" => 'risky_or_exploitive_situations_score',
      "Involvement in Higher Risk and/or Exploitive Situations Notes:" => 'risky_or_exploitive_situations_notes',
      "Interaction with Emergency Services Scoring" => 'emergency_services_score',
      "Interaction with Emergency Services Notes:" => 'emergency_services_notes',
      "Legal Scoring" => 'legal_services_score',
      "Legal Notes:" => 'legal_services_notes',
      "Managing Tenancy Scoring" => 'managing_tenancy_score',
      "Managing Tenancy Notes:" => 'managing_tenancy_notes',
      "Personal Administration & Money Management Scoring" => 'money_management_score',
      "Personal Administration & Money Management Notes:" => 'money_management_notes',
      "Social Relationships & Networks Scoring" => 'social_relationships_score',
      "Social Relationships & Networks Notes:" => 'social_relationships_notes',
      "Self Care & Daily Living Skills Scoring" => 'life_skills_score',
      "Self Care & Daily Living Skills Notes:" => 'life_skills_notes',
      "Meaningful Daily Activity Scoring" => 'meaningful_activity_score',
      "Meaningful Daily Activity Notes:" => 'meaningful_activity_notes',
      "History of Homelessness Scoring" => 'history_of_homelessness_score',
      "History of Homelessness Notes:" => 'history_of_homelessness_notes',
    }.transform_values { |v| "spdat-#{v}" }

    def build_assessment_records(rows)
      personal_id_by_enrollment_id = Hmis::Hud::Enrollment
        .where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h

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
      owner_id_by_assessment_id = Hmis::Hud::CustomAssessment
        .where(data_source: data_source)
        .pluck(:CustomAssessmentID, :id)
        .to_h

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
        raise "unexpected value #{value} for #{row.inspect}" unless value =~/^[0-9].*/

        score = value&.to_i
        value = "#{cded_key}-#{score}"
      end
    end

    def model_class
      Hmis::Hud::CustomAssessment
    end
  end
end
