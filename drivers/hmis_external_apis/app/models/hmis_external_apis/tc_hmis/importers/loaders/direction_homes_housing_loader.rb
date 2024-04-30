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
      { label: 'Date Application Received', key: 'date_app_received', repeats: false, field_type: 'date' },
      { label: 'Date Application Completed', key: 'date_app_completed', repeats: false, field_type: 'date' },
      { label: 'Date Given Voucher and Briefing Date', key: 'date_given_voucher', repeats: false, field_type: 'date' },
      { label: 'Passed Inspection Date', key: 'date_passed_inspection', repeats: false, field_type: 'date' },
      { label: 'Move in Date', key: 'move_in_date', repeats: false, field_type: 'date' },
    ].map { |h| h.merge(key: "direction_homes_housing_#{h[:key]}") }.freeze


    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "direction-homes-housing-application-info-eto-#{response_id}"
    end

    def form_definition_identifier
      'direction-homes-housing-application-info'
    end
  end
end
