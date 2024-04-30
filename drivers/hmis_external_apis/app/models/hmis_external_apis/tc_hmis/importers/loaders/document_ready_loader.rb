###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class DocumentReadyLoader < CustomAssessmentLoader
    ASSESSMENT_DATE_COL = 'Date Taken'.freeze

    def filename
      'DocumentReady.xlsx'
    end

    CDED_CONFIGS = [
      { label: 'Household Type', key: 'document_ready_household_type', repeats: false, field_type: 'string' },
      { label: 'Is the participant assigned to a navigator?', key: 'assigned_navigator', repeats: false, field_type: 'boolean' },
      { label: 'If No', key: 'if_no_navigator', repeats: false, field_type: 'string' },
      { label: 'If shelter choose one.', key: 'if_shelter_choose', repeats: false, field_type: 'string' },
      { label: 'If outreach choose one', key: 'if_outreach_choose', repeats: false, field_type: 'string' },
      { label: 'Are all required documents uploaded into ETO?', key: 'all_required_documents_uploaded', repeats: false, field_type: 'boolean' },
      { label: 'Which documents are missing?', key: 'missing', repeats: true, field_type: 'string' },
      { label: 'Case Notes.', key: 'case_notes', repeats: false, field_type: 'string' },
      { label: "If Yes (Navigator's Name)", key: 'navigator_name', repeats: false, field_type: 'string' },
      { label: 'Status', key: 'status', repeats: false, field_type: 'string' },
      { label: 'Staff adding.', key: 'staff_name', repeats: false, field_type: 'string' },
      { label: 'Status Notes', key: 'status_notes', repeats: false, field_type: 'string' },
      { label: 'Service Provider', key: 'service_provider', repeats: false, field_type: 'string' },
      { label: 'Assessor', key: 'assessor', repeats: false, field_type: 'string' },
    ].map { |h| h.merge(key: "document_ready_#{h[:key]}") }.freeze

    protected

    def cded_configs
      CDED_CONFIGS
    end

    def row_assessment_date(row)
      parse_date(row.field_value(ASSESSMENT_DATE_COL))
    end

    def row_assessment_id(row)
      response_id = row.field_value(RESPONSE_ID_COL)
      "document-ready-eto-#{response_id}"
    end

    def form_definition_identifier
      'document-ready'
    end
  end
end
