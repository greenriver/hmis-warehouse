###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class UhaLoader < CustomAssessmentLoader

    ASSESSMENT_DATE_COL = 'Date Taken'.freeze
    ALT_MAILING_ADDRESS_CONFIGS = [
      { label: 'Alternate Mailing Address', id: 12275, key: "uha_alt_zip", repeats: false, field_type: 'string' },
      { label: 'Name', id: 12327, key: "uha_alt_name", repeats: false, field_type: 'string' },
    ]

    GENERAL_CONFIGS = [
      { label: 'Program Name', key: 'uha_program_name', repeats: false, field_type: 'string' },
      { label: 'Case Number', key: 'uha_case_number', repeats: false, field_type: 'string' },
      { label: 'Participant Enterprise Identifier', key: 'uha_participant_enterprise_identifier', repeats: false, field_type: 'string' },
    ]

    CDED_CONFIGS = (
      GENERAL_CONFIGS + ALT_MAILING_ADDRESS_CONFIGS
    )

    def filename
      'UHA.xlsx'
    end

    protected

    def cded_configs
      CDED_CONFIGS
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
