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
      { element_id: 10633, key: 'form_type', repeats: false, field_type: 'string' },
      { element_id: 10635, key: 'employer_address_name', repeats: false, field_type: 'string' },
      { element_id: 10636, key: 'employer_address_company', repeats: false, field_type: 'string' },
      { element_id: 10637, key: 'employer_address_1', repeats: false, field_type: 'string' },
      { element_id: 10638, key: 'employer_address_2', repeats: false, field_type: 'string' },
      { element_id: 10639, key: 'employer_address_city', repeats: false, field_type: 'string' },
      { element_id: 10641, key: 'employer_address_county', repeats: false, field_type: 'string' },
      { element_id: 10640, key: 'employer_address_state', repeats: false, field_type: 'string' },
      { element_id: 10642, key: 'employer_address_zip', repeats: false, field_type: 'string' },
      { element_id: 10643, key: 'current_job_title', repeats: false, field_type: 'string' },
      { element_id: 10644, key: 'date_of_hire', repeats: false, field_type: 'string' },
      { element_id: 10645, key: 'last_date_of_employment', repeats: false, field_type: 'date' },
      { element_id: 10648, key: 'rate_of_pay', repeats: false, field_type: 'float' },
      { element_id: 10649, key: 'wages_change_reason', repeats: false, field_type: 'string' },
      { element_id: 10652, key: 'hours_per_week', repeats: false, field_type: 'integer' },
      { element_id: 10652, key: 'monthly_earnings', repeats: false, field_type: 'float' },
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
