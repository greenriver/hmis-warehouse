###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Financial::CsvImportConcern
  extend ActiveSupport::Concern
  included do
    alias_attribute :filename, :file

    def import!(force = false)
      return unless check_hour || force

      start_import
      fetch_and_load
      complete_import
    end

    # Override CSV load so that we can upsert and don't end up with duplicates when we should just be updating
    # the row we received before.  Full files are stored in the attachment
    def load_csv(file)
      batch_size = 10_000
      loaded_rows = 0

      headers = clean_headers(file.first.compact)
      file.drop(1).each_slice(batch_size) do |lines|
        loaded_rows += lines.count
        associated_class.import!(
          headers,
          clean_rows(lines),
          timestamps: false,
          on_duplicate_key_update: {
            conflict_target: conflict_target,
            columns: headers,
          },
        )
      end
      summary << "Loaded #{loaded_rows} rows"
    end

    private def clean_headers(headers)
      headers << 'data_source_id'
      headers.map do |h|
        header_lookup[h] || h
      end
    end

    # Append data_source_id
    private def clean_rows(rows)
      rows.map do |row|
        row + [data_source_id]
      end
    end
  end
end
