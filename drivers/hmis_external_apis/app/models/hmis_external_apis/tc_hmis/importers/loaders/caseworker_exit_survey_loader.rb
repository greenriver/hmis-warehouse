###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CaseworkerExitSurveyLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'CaseworkerExitSurvey.xlsx'
    end

    CDED_CONFIGS = [
      { element_id: 6204, key: 'phone', repeats: false, field_type: 'string' },
      { element_id: 6204, key: 'email', repeats: false, field_type: 'string' },
      { element_id: 6309, key: 'weeks_in_program', repeats: false, field_type: 'integer' },
      { element_id: 6208, key: 'beginning_gas_score', repeats: false, field_type: 'integer' },
      { element_id: 6213, key: 'beginning_gas_score_date', repeats: false, field_type: 'date' },
      { element_id: 6209, key: 'end_gas_score', repeats: false, field_type: 'integer' },
      { element_id: 6214, key: 'end_gas_score_date', repeats: false, field_type: 'date' },
      { element_id: 6231, key: 'gas_score_change', repeats: false, field_type: 'integer' },
      { element_id: 6212, key: 'destination', repeats: false, field_type: 'string' },
      { element_id: 8621, key: 'destination_other', repeats: false, field_type: 'string' },
      { element_id: 8619, key: 'housing_program', repeats: false, field_type: 'string' },
      { element_id: 6308, key: 'housing_program_other', repeats: false, field_type: 'string' },
      { element_id: 6221, key: 'employed_at_entry', repeats: false, field_type: 'boolean' },
      { element_id: 6223, key: 'hourly_rate_at_entry', repeats: false, field_type: 'float' },
      { element_id: 6224, key: 'employed_at_exit', repeats: false, field_type: 'boolean' },
      { element_id: 6225, key: 'hourly_rate_at_exit', repeats: false, field_type: 'float' },
      { element_id: 6235, key: 'gained_employment', repeats: false, field_type: 'integer' },
      { element_id: 6226, key: 'employment_type', repeats: false, field_type: 'string' },
      { element_id: 7109, key: 'income_increase', repeats: false, field_type: 'float' },
      { element_id: 6227, key: 'savings_at_entry', repeats: false, field_type: 'float' },
      { element_id: 6228, key: 'savings_at_exit', repeats: false, field_type: 'float' },
      { element_id: 6232, key: 'savings_difference', repeats: false, field_type: 'float' },
      { element_id: 8620, key: 'savings_source', repeats: false, field_type: 'string' },
      { element_id: 6302, key: 'special_status', repeats: false, field_type: 'string' },
      { element_id: 10530, key: 'members_in_family', repeats: false, field_type: 'integer' },
      { element_id: 6303, key: 'number_of_adults', repeats: false, field_type: 'integer' },
      { element_id: 6304, key: 'number_of_children', repeats: false, field_type: 'integer' },
      { element_id: 6305, key: 'highest_level_achieved', repeats: false, field_type: 'string' },
      { element_id: 6306, key: 'one_month_follow_up', repeats: true, field_type: 'string' },
      { element_id: 6307, key: 'referrals_at_follow_up', repeats: false, field_type: 'string' },
    ].freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "caseworker_exit-eto-#{response_id}"
    end

    def form_definition_identifier
      'caseworker_exit'
    end
  end
end
