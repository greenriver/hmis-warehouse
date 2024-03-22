###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class DiversionAssessmentLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_CONFIGS = [
      { element_id: 8839, label: 'Were you able to divert the family today?', key: 'dca_diverted', repeats: false, field_type: 'boolean' },
      { element_id: 8840,
        label: 'If they cannot be diverted today can they be diverted in the next 30 days?',
        key: 'dca_diverted_30_days',
        repeats: false,
        field_type: 'boolean' },
      { element_id: 10003,
        label: 'Where were you staying prior to entering homelessness OR what is your current housing situation?',
        key: 'dca_current_housing',
        repeats: false,
        field_type: 'string' },
      { element_id: 10658, label: 'Notes:', key: 'dca_process_notes', repeats: false, field_type: 'string' },
      { element_id: 10659, label: 'Notes:', key: 'dca_last_night_notes', repeats: false, field_type: 'string' },
      { element_id: 10660, label: 'Notes:', key: 'dca_story_notes', repeats: false, field_type: 'string' },
      { element_id: 10661, label: 'Notes:', key: 'dca_going_back_notes', repeats: false, field_type: 'string' },
      { element_id: 10662, label: 'Notes:', key: 'dca_temporary_housing_notes', repeats: false, field_type: 'string' },
      { element_id: 10663, label: 'Notes:', key: 'dca_barriers_notes', repeats: false, field_type: 'string' },
      { element_id: 10664, label: 'Notes:', key: 'dca_resources_notes', repeats: false, field_type: 'string' },
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
      "dca-eto-#{response_id}"
    end

    def form_definition_identifier
      'diversion-crisis-assessment'
    end

    def ce_assessment_level
      1 # AssessmentLevel: 1 (crisis needs assessment)
    end

    def ce_assessment_level
      1 # AssessmentLevel: 1 (crisis needs assessment)
    end
  end
end
