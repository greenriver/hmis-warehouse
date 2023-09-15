###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# reload!; reader = HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/sh_hmis/importers'); HmisExternalApis::ShHmis::Importers::Loaders::CurrentLivingSituationNoteLoader.new(clobber: false, reader: reader).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  # TODO: do we want to load this as notes, or attach them to CLS records?
  class CurrentLivingSituationNoteLoader < CustomDataElementBaseLoader
    def filename
      'OutreachAndServicesContacts.csv'
    end

    protected

    def cde_definitions_keys
      [:current_living_sitution_note]
    end

    def build_records
      cls_id_header = 'Response Unique Identifier'
      cls_lookup = owner_class.where(data_source: data_source)
        .pluck(:CurrentLivingSitID, :id)
        .to_h

      expected = 0
      records = rows.map do |row|
        question = row_value(row, field: 'Question')
        next unless question == 'Notes'

        note_value = row_value(row, field: 'Answer', required: false)
        next if note_value.blank?

        expected += 1
        cls_id = row_value(row, field: cls_id_header)
        cls_lookup_pk = cls_lookup[cls_id]

        unless cls_lookup_pk
          log_skipped_row(row, field: cls_id_header)
          next # early return
        end

        new_cde_record(
          value: note_value,
          definition_key: cde_definitions_keys.first,
        ).merge(owner_id: cls_lookup_pk)
      end.compact
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def owner_class
      Hmis::Hud::CurrentLivingSituation
    end
  end
end
