###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# todays_urgency_and_options

module HmisExternalApis::TcHmis::Importers::Loaders
  class DiversionAssessmentLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { element_id: nil, label: 'Program Name', key: 'div_program_name', repeats: false, field_type: 'string' },
      { element_id: nil, label: 'Case Number', key: 'div_case_number', repeats: false, field_type: 'string' },
      { element_id: 8827, label: 'Date of assessment', key: 'div_date_of_assessment', repeats: false, field_type: 'string' },
      { element_id: 8829, label: 'Assessment Type', key: 'div_assessment_type', repeats: false, field_type: 'string' },
      { element_id: 8830, label: 'Assessment Level', key: 'div_assessment_level', repeats: false, field_type: 'string' },
      { element_id: 8831, label: 'Assessment Location', key: 'div_assessment_location', repeats: false, field_type: 'string' },
      { element_id: 8839,
        label: 'Were you able to divert the family today?',
        key: 'div_diverted_today',
        repeats: false,
        field_type: 'string' },
      { element_id: 8840,
        label: 'If they cannot be diverted today can they be diverted in the next 30 days?',
        key: 'div_diverted_in_next_30_days',
        repeats: false,
        field_type: 'string' },
      { element_id: 10003,
        label: 'Where were you staying prior to entering homelessness OR what is your current housing situation?',
        key: 'div_prior_or_current_housing_situation',
        repeats: false,
        field_type: 'string' },
      { element_id: 10658, label: 'Notes:', key: 'div_todays_urgency_and_options_notes', repeats: false, field_type: 'string' },
      { element_id: 10659, label: 'Notes:', key: 'div_last_night_notes', repeats: false, field_type: 'string' },
      { element_id: 10660, label: 'Notes:', key: 'div_story_behind_the_story_notes', repeats: false, field_type: 'string' },
      { element_id: 10661, label: 'Notes:', key: 'div_what_would_it_take_to_go_back_notes', repeats: false, field_type: 'string' },
      { element_id: 10662, label: 'Notes:', key: 'div_new_place_to_stay_notes', repeats: false, field_type: 'string' },
      { element_id: 10663, label: 'Notes:', key: 'div_identify_barriers_notes', repeats: false, field_type: 'string' },
      { element_id: 10664, label: 'Notes:', key: 'div_current_resources_notes', repeats: false, field_type: 'string' },
      { element_id: 11943, label: 'Prioritization Status', key: 'div_prioritization_status', repeats: false, field_type: 'string' },
    ].freeze

    def filename
      'diversion_assessment.xlsx'
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
      "div-eto-#{response_id}"
    end

    def form_definition
      Hmis::Form::Definition.where(identifier: 'diversion-crisis-assessment').first!
    end
  end
end
