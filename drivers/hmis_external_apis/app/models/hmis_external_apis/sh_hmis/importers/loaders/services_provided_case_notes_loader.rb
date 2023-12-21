###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# require 'csv'
# ENV['SH_HMIS_IMPORT_LOG_FILE'] = "var/#{Date.current.strftime('%Y-%m-%d')}-migration-log.txt"
# reader = HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('var')
# HmisExternalApis::ShHmis::Importers::Loaders::ServicesProvidedCaseNotesLoader.new(clobber: false, reader: reader).perform

# before = Hmis::Hud::CustomCaseNote.all.size
module HmisExternalApis::ShHmis::Importers::Loaders
  class ServicesProvidedCaseNotesLoader < SingleFileLoader
    def perform
      records = build_records
      # DONT CLOBBER
      # model_class.where(data_source: data_source).each(&:really_destroy!) if clobber
      ar_import(model_class, records)
    end

    def filename
      'ServicesProvided.csv'
    end

    protected

    def build_records
      enrollment_id_to_personal_id = Hmis::Hud::Enrollment.where(data_source: data_source).
        pluck(:enrollment_id, :personal_id).to_h

      # { Unique ID => CustomCaseNote hash }
      records_by_id = {}
      expected = 0
      rows.each do |row|
        # row_personal_id = row_value(row, field: 'Participant Enterprise Identifier', required: false)
        enrollment_id = row_value(row, field: 'Unique Enrollment Identifier', required: false)
        unique_note_id = row_value(row, field: 'Response Unique Identifier')
        expected += 1 unless records_by_id.key?(unique_note_id)

        unless enrollment_id
          log_info 'Skipping, no Enrollment ID'
          next
        end

        # its ok if the personal id doesnt match because they may have been merged. go off enrollment id only
        personal_id = enrollment_id_to_personal_id[enrollment_id]
        unless personal_id
          log_skipped_row(row, field: 'Unique Enrollment Identifier')
          next
        end

        date_taken = parse_date(row_value(row, field: 'Date Taken'))
        date_last_updated = parse_date(row_value(row, field: 'Date Last Updated'))

        records_by_id[unique_note_id] ||= begin
          attrs = {
            CustomCaseNoteID: Hmis::Hud::Base.generate_uuid,
            EnrollmentID: enrollment_id,
            PersonalID: personal_id,
            information_date: date_taken,
            DateCreated: date_taken,
            DateUpdated: date_last_updated,
            UserID: user_id_from_staff_id(row),
          }
          default_attrs.merge(attrs)
        end

        records_by_id[unique_note_id][:DateCreated] = [records_by_id[unique_note_id][:DateCreated], date_taken].min
        records_by_id[unique_note_id][:DateUpdated] = [records_by_id[unique_note_id][:DateUpdated], date_last_updated].max

        question = row_value(row, field: 'Question')
        answer = row_value(row, field: 'Answer', required: false)&.strip
        next if answer.blank?

        case question
        when 'Date of Contact'
          info_date = parse_date(answer)&.to_date
          records_by_id[unique_note_id][:information_date] = info_date if info_date
        when 'Contact Location / Method'
          records_by_id[unique_note_id][:location] = "Location: #{answer}"
        when 'Date of Next Contact'
          next_date = parse_date(answer)&.to_date
          records_by_id[unique_note_id][:next_contact] = "Date of Next Contact: #{next_date.strftime('%m/%d/%Y')}" if next_date
        when 'HUD Services Provided'
          services = answer.split('|')&.compact_blank&.join(', ')
          records_by_id[unique_note_id][:services_provided] = "Services Provided: #{services}"
        when 'Time Spent'
          records_by_id[unique_note_id][:time_spent] = "Time Spent: #{answer}"
        when 'Notes'
          records_by_id[unique_note_id][:notes] = answer
        end
      end

      records = []
      records_by_id.each do |id, hash|
        note_keyset = [:location, :next_contact, :services_provided, :time_spent, :notes]
        left, right = hash.partition { |k, _v| note_keyset.include?(k) }.map(&:to_h)

        left.compact_blank!

        unless left[:services_provided] || left[:notes]
          log_info "Skipping #{id} because there was no meaningful note content"
          next
        end

        content = []
        content << "#{left[:notes]}\n" if left[:notes]
        content << left[:services_provided]
        content << left[:location]
        content << left[:time_spent]
        content << left[:next_contact]

        note_content = content.compact.join("\n")
        right[:content] = note_content
        records << right unless note_content.blank?
      end

      log_processed_result(expected: expected, actual: records.size)

      # binding.pry
      # []
      records
    end

    def model_class
      Hmis::Hud::CustomCaseNote
    end
  end
end
