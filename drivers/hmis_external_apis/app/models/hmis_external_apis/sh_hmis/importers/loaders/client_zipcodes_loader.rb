###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HmisExternalApis::ShHmis::Importers::Loaders::ClientZipcodesLoader.new(clobber: false, reader: HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('.')).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  class ClientZipcodesLoader < SingleFileLoader
    def filename
      'ClientZipcodes.csv'
    end

    def perform
      records = build_records
      # destroy existing records and re-import
      model_class.where(data_source: data_source).each(&:really_destroy!) if clobber
      ar_import(model_class, records)
    end

    protected

    def build_records
      zip_header = 'Zip Code'
      participant_header = 'Participant Enterprise Identifier'
      client_lookup = Hmis::Hud::Client.
        where(data_source: data_source).
        pluck(:personal_id, :id).
        to_h

      # { PersonalID => [Zips] }
      seen = {}
      expected = 0
      records = rows.map do |row|
        value = row_value(row, field: zip_header, required: false)
        next if value.blank?

        expected += 1
        personal_id = row_value(row, field: participant_header)
        client_id = client_lookup[personal_id]

        unless client_id
          log_skipped_row(row, field: participant_header)
          next # early return
        end

        seen[personal_id] ||= []
        # dont add duplicate addresses with the same zip
        next if seen[personal_id].include?(value)

        seen[personal_id] << value
        attrs = {
          AddressID: Hmis::Hud::Base.generate_uuid,
          PersonalID: personal_id,
          postal_code: value,
          DateCreated: current_datetime,
          DateUpdated: current_datetime,
        }
        default_attrs.merge(attrs)
      end.compact
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def model_class
      Hmis::Hud::CustomClientAddress
    end
  end
end
