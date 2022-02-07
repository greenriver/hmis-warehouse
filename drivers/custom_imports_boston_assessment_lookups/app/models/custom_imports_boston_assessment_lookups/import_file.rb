###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonAssessmentLookups
  class ImportFile < GrdaWarehouse::CustomImports::ImportFile
    has_many :rows

    def self.description
      'Boston Custom Assessment Lookups'
    end

    def detail_path
      [:custom_imports, :boston_assessment_lookups, :file]
    end

    def filename
      file
    end

    def import!(force = false)
      return unless check_hour || force

      start_import
      fetch_and_load
      post_process
      log_summary
    end

    # CSV is missing a header for row_number, needs import_file_id, and the others need to be translated
    private def clean_headers(headers)
      headers << 'import_file_id'
      headers << 'data_source_id'
      headers.map do |h|
        header_lookup[h] || h
      end
    end

    private def header_lookup
      {
        'Field Name' => 'assessment_question',
        'Numeric Response' => 'response_code',
        'Text Response' => 'response_text',
      }
    end

    def post_process
      update(status: 'adding')
      GrdaWarehouse::AssessmentAnswerLookup.transaction do
        GrdaWarehouse::AssessmentAnswerLookup.where(data_source_id: data_source_id).delete_all
        headers = [
          :assessment_question,
          :response_code,
          :response_text,
          :data_source_id,
        ]
        GrdaWarehouse::AssessmentAnswerLookup.import(headers, rows.pluck(*headers))
      end

      update(status: 'complete', completed_at: Time.current)
    end
  end
end
