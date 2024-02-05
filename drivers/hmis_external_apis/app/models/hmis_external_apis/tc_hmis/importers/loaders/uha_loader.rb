###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class UhaLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    CDED_FIELD_TYPE_MAP = {
      # 'travel_time_minutes' => 'integer',
    }.freeze

    CDED_COL_MAP = {
      'Program Name' => 'program_name',
      'Case Number' => 'case_number',
      'Participant Enterprise Identifier' => 'participant_enterprise_identifier',
      #

    }.to_a.map do |label, key|
      {
        label: label.gsub(/\s+/, ' '), # normalize whitespace
        key: "uha-#{key}",
        repeats: false,
        field_type: CDED_FIELD_TYPE_MAP[key] || 'string',
      }
    end

    def filename
      'UHA.xlsx'
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
      "uha-eto-#{response_id}"
    end
  end
end
