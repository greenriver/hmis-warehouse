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
      { label: 'Phone Number', key: 'phone', repeats: false, field_type: 'string' },
      { label: 'Email', key: 'email', repeats: false, field_type: 'string' },
      { label: 'Beginning GAS score', key: 'beginning_gas_score', repeats: false, field_type: 'integer' },
      { label: 'Exit GAS score', key: 'end_gas_score', repeats: false, field_type: 'integer' },
      { label: 'Where will the client be residing? (Please check one).', key: 'destination', repeats: false, field_type: 'string' },
      { label: 'Beginning GAS Score Date', key: 'beginning_gas_score_date', repeats: false, field_type: 'date' },
      { label: 'Exit GAS Score Date', key: 'end_gas_score_date', repeats: false, field_type: 'date' },
      { label: 'Was resident employed when they entered the shelter?', key: 'employed_at_entry', repeats: false, field_type: 'boolean' },
      { label: 'Hourly rate at enrollment', key: 'hourly_rate_at_entry', repeats: false, field_type: 'float' },
      { label: 'Is resident employed at time of exit?', key: 'employed_at_exit', repeats: false, field_type: 'boolean' },
      { label: 'Hourly rate at exit', key: 'hourly_rate_at_exit', repeats: false, field_type: 'float' },
      { label: 'If employed at exit was it:', key: 'employment_type', repeats: false, field_type: 'string' },
      { label: 'How much money did the resident have in savings when entering the shelter?', key: 'savings_at_entry', repeats: false, field_type: 'float' },
      { label: 'How much money did the resident have in savings when exiting the shelter?', key: 'savings_at_exit', repeats: false, field_type: 'float' },
      { label: 'Difference/Change in GAS score', key: 'gas_score_change', repeats: false, field_type: 'integer' },
      { label: 'Difference between savings', key: 'savings_difference', repeats: false, field_type: 'float' },
      { element_id: 6235, key: 'gained_employment', repeats: false, field_type: 'integer' },
      { label: 'Special status', key: 'special_status', repeats: false, field_type: 'string' },
      { label: 'Number of adults', key: 'number_of_adults', repeats: false, field_type: 'integer' },
      { label: 'Number of children', key: 'number_of_children', repeats: false, field_type: 'integer' },
      { label: 'Highest level achieved in shelter', key: 'highest_level_achieved', repeats: false, field_type: 'string' },
      { label: 'One month follow-up', key: 'one_month_follow_up', repeats: true, field_type: 'string' },
      { label: 'Referrals given at follow-up', key: 'referrals_at_follow_up', repeats: false, field_type: 'string' },
      { label: 'If other  housing program, please specify which one.', key: 'housing_program_other', repeats: false, field_type: 'string' },
      { label: 'Number of weeks in program', key: 'weeks_in_program', repeats: false, field_type: 'integer' },
      { label: 'How much did income increase while in shelter?', key: 'income_increase', repeats: false, field_type: 'float' },
      { label: 'If client exited to a housing program, which program was it?', key: 'housing_program', repeats: false, field_type: 'string' },
      { label: 'If client left with savings, was it from employment, benefits, both or other? (choose one answer)', key: 'savings_source', repeats: false, field_type: 'string' },
      { label: 'If other, please specify exit destination.', key: 'destination_other', repeats: false, field_type: 'string' },
      { label: 'How many members in family?', key: 'members_in_family', repeats: false, field_type: 'integer' },
    ].map { |h| h.merge(key: "caseworker_exit_#{h[:key]}") }.freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "caseworker-exit-eto-#{response_id}"
    end

    def form_definition_identifier
      'caseworker_exit_survey'
    end
  end
end
