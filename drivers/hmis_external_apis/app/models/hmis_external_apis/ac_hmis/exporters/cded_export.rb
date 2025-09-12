###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class CdedExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    EXCLUDED_CUSTOM_DATA_ELEMENT_KEYS = [
      'client_pathway_1',
      'client_pathway_2',
      'client_pathway_3',
      'client_pathway_1_date',
      'client_pathway_2_date',
      'client_pathway_3_date',
      'client_pathway_1_narrative',
      'client_pathway_2_narrative',
      'client_pathway_3_narrative',
    ].freeze

    def run!
      Rails.logger.info 'Generating CDED report'
      write_row(columns)
      total = cdeds.count
      Rails.logger.info "There are #{total} CDEDs to export"

      cdeds.each.with_index do |cded, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 100).zero?
        values = [
          cded.key,
          cded.owner_type.demodulize,
          cded.field_type,
          cded.label,
          cded.form_definition_identifier,
        ]
        write_row(values)
      end
    end

    private

    def columns
      [
        'CustomFieldKey', # maps to CustomFieldKey in CustomFieldValues.csv
        'RecordType', # eg 'Service', 'CustomAssessment', 'Client'
        'FieldType', # eg 'string', 'integer'
        'Label', # human-readable label for this field
        'AssessmentKey', # maps to AssessmentKey in CustomAssessments.csv if RecordType is CustomAssessment
      ]
    end

    def cdeds
      @cdeds ||= Hmis::Hud::CustomDataElementDefinition.where(data_source: data_source).
        where.not(key: EXCLUDED_CUSTOM_DATA_ELEMENT_KEYS)
    end
  end
end
