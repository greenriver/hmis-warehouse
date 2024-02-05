###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class SpdatLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

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
      'Which SPDAT is this?' => 'assessment_event',
      'Travel Time' => 'travel_time_minutes',
      'Time Spent' => 'time_spent_minutes',
      'Contact Location / Method' => 'client_contact_location_and_method',
      'SPDAT Score' => 'total_score',
      'SPDAT Notes' => 'score_notes',
      'Is this assessment being completed for a dismissed client or a client who is no longer in contact?' => 'assessment_is_for_absent_client',
      'How long has the client been out of contact (in days)?' => 'assessment_absent_days',
      'Mental Health & Wellness & Cognitive Functioning Scoring' => 'mental_health_score',
      'Mental Health & Wellness & Cognitive Functioning Notes:' => 'mental_health_notes',
      'Physical Health & Wellness Scoring' => 'physical_health_score',
      'Physical Health & Wellness Notes:' => 'physical_health_notes',
      'Medication Scoring' => 'medication_score',
      'Medication Notes:' => 'medication_notes',
      'Substance Use Scoring' => 'substance_use_score',
      'Substance Use Notes:' => 'substance_use_notes',
      'Experience of Abuse & Trauma Scoring' => 'abuse_and_trauma_score',
      'Experience of Abuse & Trauma Notes:' => 'abuse_and_trauma_notes',
      'Risk of Harm to Self or Others Scoring' => 'risk_of_harm_score',
      'Risk of Harm to Self or Others Notes:' => 'risk_of_harm_notes',
      'Involvement in Higher Risk and/or Exploitive Situations Scoring' => 'risky_or_exploitive_situations_score',
      'Involvement in Higher Risk and/or Exploitive Situations Notes:' => 'risky_or_exploitive_situations_notes',
      'Interaction with Emergency Services Scoring' => 'emergency_services_score',
      'Interaction with Emergency Services Notes:' => 'emergency_services_notes',
      'Legal Scoring' => 'legal_services_score',
      'Legal Notes:' => 'legal_services_notes',
      'Managing Tenancy Scoring' => 'managing_tenancy_score',
      'Managing Tenancy Notes:' => 'managing_tenancy_notes',
      'Personal Administration & Money Management Scoring' => 'money_management_score',
      'Personal Administration & Money Management Notes:' => 'money_management_notes',
      'Social Relationships & Networks Scoring' => 'social_relationships_score',
      'Social Relationships & Networks Notes:' => 'social_relationships_notes',
      'Self Care & Daily Living Skills Scoring' => 'life_skills_score',
      'Self Care & Daily Living Skills Notes:' => 'life_skills_notes',
      'Meaningful Daily Activity Scoring' => 'meaningful_activity_score',
      'Meaningful Daily Activity Notes:' => 'meaningful_activity_notes',
      'History of Homelessness Scoring' => 'history_of_homelessness_score',
      'History of Homelessness Notes:' => 'history_of_homelessness_notes',
    }.to_a.map do |label, key|
      {
        label: label.gsub(/\s+/, ' '), # normalize whitespace
        key: "spdat-#{key}",
        repeats: false,
        field_type: CDED_FIELD_TYPE_MAP[key] || 'string',
      }
    end

    def filename
      'SPDAT.xlsx'
    end

    protected

    def cded_configs
      CDED_COL_MAP
    end

    def row_assessment_date(row)
      row.field_value(ASSESSMENT_DATE_COL)
    end

    # use the eto response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "spdat-eto-#{response_id}"
    end

    def cde_values(row, config)
      cded_key = config.fetch(:key)
      values = super(row, config)
      if cded_key =~ /^(?!spdat-total_score$).*_score$/
        values.map do |value|
          # score choice values start with integer which is the score
          raise "unexpected value #{value} for #{row.inspect}" unless value =~ /^[0-9].*/

          "#{cded_key}-#{value&.to_i}"
        end
      end
      values
    end
  end
end
