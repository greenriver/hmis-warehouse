###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class ScanCardLoader < BaseLoader
    def initialize(...)
      super

      @client_lookup = Hmis::Hud::Client.
        where(data_source_id: data_source.id).
        pluck(:personal_id, :id).
        to_h

      @now = Time.current
    end

    def filename
      'ScanCodes.xlsx'
    end

    # why not define this in BaseLoader?
    def runnable?
      super && reader.file_present?(filename)
    end

    def perform
      Hmis::ScanCardCode.with_deleted.delete_all if clobber

      actual = 0
      expected = 0
      scan_cards = []
      unique_codes = Set.new

      rows = reader.rows(filename: filename)
      rows.each do |row|
        expected += 1

        case_number = row.field_value_by_id('Case Number')
        next unless case_number && case_number.length > 1

        if !case_number.starts_with?('P')
          # not expected, the report should already filter them out
          log_skipped_row(row, field: 'Case Number')
          next
        end

        personal_id = normalize_uuid(row.field_value_by_id('Participant Enterprise Identifier'))
        next unless personal_id

        # Couldn't find a match for this PersonalID. Log and skip.
        client_id = @client_lookup[personal_id]
        unless client_id
          log_skipped_row(row, field: 'Participant Enterprise Identifier')
          next
        end

        # If we already generated a ScanCardCode with this code, skip. Scan card codes must be unique.
        if unique_codes.include?(case_number)
          log_info "#{row.context} code is not unique \"#{case_number}\""
          next
        end

        actual += 1
        unique_codes.add(case_number)
        timestamp = parse_date(row.field_value_by_id('Date Last Updated')) || @now
        scan_cards << Hmis::ScanCardCode.new(
          client_id: client_id,
          value: case_number,
          created_by: system_user,
          created_at: timestamp,
          updated_at: timestamp,
        )
      end

      ar_import(Hmis::ScanCardCode, scan_cards) if scan_cards.any?

      log_processed_result(name: 'Scan Card Codes', expected: expected, actual: actual)
    end
  end
end
