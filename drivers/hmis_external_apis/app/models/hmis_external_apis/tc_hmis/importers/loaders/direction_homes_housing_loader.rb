###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class DirectionHomesHousingLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'DirectionHomes.xlsx'
    end

    CDED_CONFIGS = [
      { element_id: 8358, key: 'date_app_received', repeats: false, field_type: 'date' },
      { element_id: 8360, key: 'date_given_voucher', repeats: false, field_type: 'date' },
      { element_id: 8359, key: 'date_app_completed', repeats: false, field_type: 'date' },
      { element_id: 8362, key: 'date_passed_inspection', repeats: false, field_type: 'date' },
      { element_id: 8362, key: 'move_in_date', repeats: false, field_type: 'date' },
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
      "direction_homes_housing-eto-#{response_id}"
    end

    def form_definition_identifier
      'direction_homes_housing'
    end
  end
end
