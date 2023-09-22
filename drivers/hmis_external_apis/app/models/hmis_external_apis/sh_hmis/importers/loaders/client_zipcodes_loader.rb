###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HmisExternalApis::ShHmis::Importers::Loaders::ClientZipcodesLoader.new(clobber: false, reader: HmisExternalApis::ShHmis::Importers::Loaders::CsvReader.new('.')).perform
module HmisExternalApis::ShHmis::Importers::Loaders
  class ClientZipcodesLoader < CustomDataElementBaseLoader
    def filename
      'ClientZipcodes.csv'
    end

    protected

    def cde_definitions_keys
      [:zipcode]
    end

    def build_records
      zip_header = 'Zip Code'
      participant_header = 'Participant Enterprise Identifier'
      client_lookup = owner_class.
        where(data_source: data_source).
        pluck(:personal_id, :id).
        to_h

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

        new_cde_record(
          value: value,
          definition_key: cde_definitions_keys.first,
        ).merge(owner_id: client_id)
      end.compact
      log_processed_result(expected: expected, actual: records.size)
      records
    end

    def owner_class
      Hmis::Hud::Client
    end
  end
end
