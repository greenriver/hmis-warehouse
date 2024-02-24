###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class SpdatLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { label: 'Date Taken', key: 'spdat_date_taken', repeats: false, field_type: 'date' },
      { label: 'Which SPDAT is this?', key: 'spdat_assessment_event', repeats: false, field_type: 'string' },
      { label: 'Travel Time', key: 'spdat_travel_time_minutes', repeats: false, field_type: 'integer' },
      { label: 'Time Spent', key: 'spdat_time_spent_minutes', repeats: false, field_type: 'integer' },
      { label: 'Contact Location / Method', key: 'spdat_client_contact_location_and_method', repeats: false, field_type: 'string' },
      { label: 'SPDAT Score', key: 'spdat_total_score', repeats: false, field_type: 'integer' },
      { label: 'SPDAT Notes', key: 'spdat_score_notes', repeats: false, field_type: 'string' },
      { label: 'Is this assessment being completed for a dismissed client or a client who is no longer in contact?',
        key: 'spdat_assessment_is_for_absent_client',
        repeats: false,
        field_type: 'string' },
      { label: 'How long has the client been out of contact (in days)?', key: 'spdat_assessment_absent_days', repeats: false, field_type: 'integer' },
      { label: 'Mental Health & Wellness & Cognitive Functioning Scoring', key: 'spdat_mental_health_score', repeats: false, field_type: 'string' },
      { label: 'Mental Health & Wellness & Cognitive Functioning Notes:', key: 'spdat_mental_health_notes', repeats: false, field_type: 'string' },
      { label: 'Physical Health & Wellness Scoring', key: 'spdat_physical_health_score', repeats: false, field_type: 'string' },
      { label: 'Physical Health & Wellness Notes:', key: 'spdat_physical_health_notes', repeats: false, field_type: 'string' },
      { label: 'Medication Scoring', key: 'spdat_medication_score', repeats: false, field_type: 'string' },
      { label: 'Medication Notes:', key: 'spdat_medication_notes', repeats: false, field_type: 'string' },
      { label: 'Substance Use Scoring', key: 'spdat_substance_use_score', repeats: false, field_type: 'string' },
      { label: 'Substance Use Notes:', key: 'spdat_substance_use_notes', repeats: false, field_type: 'string' },
      { label: 'Experience of Abuse & Trauma Scoring', key: 'spdat_abuse_and_trauma_score', repeats: false, field_type: 'string' },
      { label: 'Experience of Abuse & Trauma Notes:', key: 'spdat_abuse_and_trauma_notes', repeats: false, field_type: 'string' },
      { label: 'Risk of Harm to Self or Others Scoring', key: 'spdat_risk_of_harm_score', repeats: false, field_type: 'string' },
      { label: 'Risk of Harm to Self or Others Notes:', key: 'spdat_risk_of_harm_notes', repeats: false, field_type: 'string' },
      { label: 'Involvement in Higher Risk and/or Exploitive Situations Scoring', key: 'spdat_risky_or_exploitive_situations_score', repeats: false, field_type: 'string' },
      { label: 'Involvement in Higher Risk and/or Exploitive Situations Notes:', key: 'spdat_risky_or_exploitive_situations_notes', repeats: false, field_type: 'string' },
      { label: 'Interaction with Emergency Services Scoring', key: 'spdat_emergency_services_score', repeats: false, field_type: 'string' },
      { label: 'Interaction with Emergency Services Notes:', key: 'spdat_emergency_services_notes', repeats: false, field_type: 'string' },
      { label: 'Legal Scoring', key: 'spdat_legal_services_score', repeats: false, field_type: 'string' },
      { label: 'Legal Notes:', key: 'spdat_legal_services_notes', repeats: false, field_type: 'string' },
      { label: 'Managing Tenancy Scoring', key: 'spdat_managing_tenancy_score', repeats: false, field_type: 'string' },
      { label: 'Managing Tenancy Notes:', key: 'spdat_managing_tenancy_notes', repeats: false, field_type: 'string' },
      { label: 'Personal Administration & Money Management Scoring', key: 'spdat_money_management_score', repeats: false, field_type: 'string' },
      { label: 'Personal Administration & Money Management Notes:', key: 'spdat_money_management_notes', repeats: false, field_type: 'string' },
      { label: 'Social Relationships & Networks Scoring', key: 'spdat_social_relationships_score', repeats: false, field_type: 'string' },
      { label: 'Social Relationships & Networks Notes:', key: 'spdat_social_relationships_notes', repeats: false, field_type: 'string' },
      { label: 'Self Care & Daily Living Skills Scoring', key: 'spdat_life_skills_score', repeats: false, field_type: 'string' },
      { label: 'Self Care & Daily Living Skills Notes:', key: 'spdat_life_skills_notes', repeats: false, field_type: 'string' },
      { label: 'Meaningful Daily Activity Scoring', key: 'spdat_meaningful_activity_score', repeats: false, field_type: 'string' },
      { label: 'Meaningful Daily Activity Notes:', key: 'spdat_meaningful_activity_notes', repeats: false, field_type: 'string' },
      { label: 'History of Homelessness Scoring', key: 'spdat_history_of_homelessness_score', repeats: false, field_type: 'string' },
      { label: 'History of Homelessness Notes:', key: 'spdat_history_of_homelessness_notes', repeats: false, field_type: 'string' },
    ].freeze

    def filename
      'SPDAT.xlsx'
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
      "spdat-eto-#{response_id}"
    end

    def cde_values(row, config)
      cded_key = config.fetch(:key)
      values = super(row, config)
      if cded_key =~ /^(?!spdat_total_score$).*_score$/
        values.map do |value|
          # score choice values start with integer which is the score
          raise "unexpected value #{value} for #{row.inspect}" unless value =~ /^[0-9].*/

          "#{cded_key}_#{value&.to_i}"
        end
      else
        values
      end
    end

    def form_definition
      Hmis::Form::Definition.where(identifier: 'tc-spdat').first!
    end
  end
end
