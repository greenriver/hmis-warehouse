###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonService
  class ImportFile < ::GrdaWarehouse::CustomImports::ImportFile
    has_many :rows

    def self.description
      'Boston Custom Services'
    end

    def detail_path
      [:custom_imports, :boston_services, :file]
    end

    def filename
      file
    end

    def import!(force = false)
      return unless check_hour || force

      start_import
      fetch_and_load
      post_process
    end

    # Override CSV load so that we can upsert and don't end up with duplicates when we should just be updating
    # the row we received before.  Full files are stored in the attachment
    def load_csv(file)
      batch_size = 10_000
      loaded_rows = 0

      headers = clean_headers(file.first)
      file.drop(1).each_slice(batch_size) do |lines|
        loaded_rows += lines.count
        cleaned_headers = headers.reject { |h| h == 'do_not_import' }

        # Check for any headers we don't know how to handle
        raise "Unable to import, headers in #{filename} do not match expectation" unless (cleaned_headers - rows.klass.column_names).empty?

        rows.klass.import!(
          cleaned_headers,
          clean_rows(headers, lines),
          on_duplicate_key_update: {
            conflict_target: [:service_id],
            columns: cleaned_headers,
          },
        )
      end
      summary << "Loaded #{loaded_rows} rows"
    end

    # CSV is missing a header for row_number, needs import_file_id, and the others need to be translated
    private def clean_headers(headers)
      headers[0] = 'row_number'
      headers << 'import_file_id'
      headers << 'data_source_id'
      headers.map do |h|
        header_lookup[h] || h
      end
    end

    private def header_lookup
      {
        'Personal ID' => 'personal_id',
        'Unique Identifier' => 'unique_id',
        'Agency ID' => 'agency_id',
        'Enrollment ID' => 'enrollment_id',
        'Service ID' => 'service_id',
        'Start Date Date' => 'date',
        'Name' => 'service_name',
        'Service Category' => 'service_category',
        'Service Item Name' => 'service_item',
        'Service Program Usage' => 'service_program_usage',
        'Service Reporting Period Start Date' => 'reporting_period_started_on',
        'Service Reporting Period End Date' => 'reporting_period_ended_on',
      }
    end

    def post_process
      update(status: 'matching')
      matched = 0
      first_row = rows.first
      period_started_on = first_row.reporting_period_started_on
      period_ended_on = first_row.reporting_period_ended_on
      CustomImportsBostonService::Row.transaction do
        ::GrdaWarehouse::Generic::Service.where(data_source_id: data_source_id, date: period_started_on..period_ended_on).delete_all
        rows.preload(:enrollment, client: :destination_client).find_in_batches do |batch|
          service_batch = []
          batch.each do |row|
            next unless row.client.present?

            matched += 1
            service_batch << {
              source_id: row.id,
              source_type: row.class.name,
              date: row.date,
              client_id: row.client.destination_client.id,
              data_source_id: data_source_id,
              title: row.service_name,
              category: row.service_category,
            }
          end
          ::GrdaWarehouse::Generic::Service.import!(
            service_batch,
            on_duplicate_key_update: {
              conflict_target: [:source_id, :source_type],
              columns: [:date, :client_id, :data_source_id],
            },
          )
        end
        summary << "Matched #{matched} services"
        update(status: 'complete', completed_at: Time.current)
      end
    end
  end
end
