###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CaseManagementAssessmentLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    # Actual values cleared, retaining the loader just for reference
    CDED_CONFIGS = [
      { key: 'cma_a1', label: 'Label', field_type: 'string', repeats: false },
      { element_id: 574, key: 'cma_a2', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a4', label: 'Label', field_type: 'integer', repeats: false },
      { element_id: 2564, key: 'cma_a5', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a6', label: 'Label', field_type: 'boolean', repeats: false },
      { key: 'cma_a13', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a20', label: 'Label', field_type: 'boolean', repeats: false },
      { key: 'cma_a30', label: 'Label', field_type: 'boolean', repeats: false },
      { key: 'cma_a31', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a32', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a33', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a34', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a35', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a36', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a37', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a38', label: 'Label', field_type: 'boolean', repeats: false },
      { key: 'cma_a39', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a40', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a41', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a42', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a43', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a44', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a45', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a46', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a47', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a48', label: 'Label', field_type: 'string', repeats: false },
      { key: 'cma_a49', label: 'Label', field_type: 'date', repeats: false },
    ].freeze

    def filename
      'CMA.xlsx'
    end

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "cma-#{response_id}"
    end

    def form_definition_identifier
      'case-management-note-assessment'
    end
  end
end
