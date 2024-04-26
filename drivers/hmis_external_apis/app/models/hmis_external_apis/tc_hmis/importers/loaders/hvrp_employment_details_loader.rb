###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class HvrpEmploymentDetailsLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'HVRPEmploymentDetails.xlsx'
    end

    CDED_CONFIGS = [
      { label: 'Employment Form Type:', key: 'form_type', repeats: false, field_type: 'string' },
      { label: 'Name', key: 'employer_address_name', repeats: false, field_type: 'string' },
      { label: 'Company', key: 'employer_address_company', repeats: false, field_type: 'string' },
      { label: 'Address Line 1', key: 'employer_address_1', repeats: false, field_type: 'string' },
      { label: 'Address Line 2', key: 'employer_address_2', repeats: false, field_type: 'string' },
      { label: 'City', key: 'employer_address_city', repeats: false, field_type: 'string' },
      { label: 'State', key: 'employer_address_state', repeats: false, field_type: 'string' },
      { label: 'County', key: 'employer_address_county', repeats: false, field_type: 'string' },
      { label: 'Zip Code', key: 'employer_address_zip', repeats: false, field_type: 'string' },
      { label: 'Current Job Title:', key: 'current_job_title', repeats: false, field_type: 'string' },
      { label: 'Date of Hire:', key: 'date_of_hire', repeats: false, field_type: 'string' },
      { label: 'Last Date of Employment:', key: 'last_date_of_employment', repeats: false, field_type: 'date' },
      { label: 'Rate of Pay:', key: 'rate_of_pay', repeats: false, field_type: 'float' },
      { label: 'Wages Change Reason (if applicable):', key: 'wages_change_reason', repeats: false, field_type: 'string' },
      { label: 'How many hours work per week?', key: 'hours_per_week', repeats: false, field_type: 'integer' },
      { label: 'Monthly Earnings', key: 'monthly_earnings', repeats: false, field_type: 'float' },
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
      "hvrp_employment_details-eto-#{response_id}"
    end

    def form_definition_identifier
      'hvrp_employment_details'
    end
  end
end
