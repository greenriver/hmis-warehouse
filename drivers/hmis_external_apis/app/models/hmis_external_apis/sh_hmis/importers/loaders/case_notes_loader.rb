###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# reload!; reader = HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('drivers/hmis_external_apis/spec/fixtures/hmis_external_apis/sh_hmis/importers'); HmisExternalApis::ShHmis::Importers::Loaders::CaseNotesLoader.new(clobber: false, reader: reader).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  class CaseNotesLoader < SingleFileLoader
    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).each(&:really_destroy!) if clobber
      ar_import(model_class, records)
    end

    def filename
      'CaseNotes.csv'
    end

    protected

    def build_records
      enrollment_id_header = 'Unique Enrollment Identifier'
      enrollment_id_to_personal_id = Hmis::Hud::Enrollment.where(data_source: data_source)
        .pluck(:enrollment_id, :personal_id)
        .to_h

      expected = 0
      records = rows.map do |row|
        note_content = row_value(row, field: 'Answer', required: false)
        next if note_content.blank?

        expected += 1
        enrollment_id = row_value(row, field: enrollment_id_header, required: false)
        next unless enrollment_id

        personal_id = enrollment_id_to_personal_id[enrollment_id]
        unless personal_id
          log_skipped_row(row, field: enrollment_id_header)
          next # early return
        end

        date_taken = row_value(row, field: 'Date Taken')
        attrs = {
          EnrollmentID: enrollment_id,
          PersonalID: personal_id,
          CustomCaseNoteID: Hmis::Hud::Base.generate_uuid,
          DateCreated: parse_date(date_taken),
          DateUpdated: parse_date(date_taken),
          content: note_content,
        }
        default_attrs.merge(attrs)
      end.compact

      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def model_class
      Hmis::Hud::CustomCaseNote
    end
  end
end
