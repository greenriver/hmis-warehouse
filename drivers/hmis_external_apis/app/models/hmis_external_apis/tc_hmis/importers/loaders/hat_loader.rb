###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# No longer used, but retained as a reference for importing CustomAssessments that are tied to CE Assessments
module HmisExternalApis::TcHmis::Importers::Loaders
  class HatLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date of assessment'.freeze

    ## element_ids added when labels do not match ETO labels
    CDED_CONFIGS = [
      { key: 'hat_a6', label: 'Label', repeats: false, field_type: 'string' },
      { key: 'hat_a7', label: 'Label', repeats: false, field_type: 'boolean' },
      { element_id: 13108, key: 'hat_a8', label: 'Label', repeats: false, field_type: 'integer' },
    ].freeze

    def filename
      'HAT.xlsx'
    end

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    # use the system response id to construct the custom assessment id
    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "hat-#{response_id}"
    end

    def form_definition_identifier
      'hat-ce-assmt'
    end

    def ce_assessment_level
      2 # AssessmentLevel 2 (housing needs assessment)
    end
  end
end
