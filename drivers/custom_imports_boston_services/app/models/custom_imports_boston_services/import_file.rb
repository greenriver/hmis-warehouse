###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonServices
  class ImportFile < GrdaWarehouse::CustomImports::ImportFile
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

    def import!
      check_hour
      start_import
      fetch_and_load
      post_process
    end

    def fetch_and_load
      return unless config.s3.present?

      file = most_recent_on_s3
      return unless file

      log("Found #{file}")
      tmp_dir = Rails.root.join('tmp', ::File.dirname(file))
      target_path = ::File.join(tmp_dir, ::File.basename(file))
      FileUtils.mkdir_p(tmp_dir)

      config.s3.fetch(
        file_name: file,
        target_path: target_path.to_s,
      )
      # store the file in the db for historic purposes
      update(
        file: file,
        content: ::File.read(target_path),
        content_type: 'text/csv',
        status: 'loading',
      )
      load_csv(target_path)
      FileUtils.remove_entry(tmp_dir)
    end

    def load_csv(file_path)
      require 'csv'
      batch_size = 10_000
      loaded_rows = 0
      ::File.open(file_path) do |file|
        headers = file.first
        file.lazy.each_slice(batch_size) do |lines|
          loaded_rows += 1
          csv_rows = CSV.parse(lines.join, headers: headers)
          CustomImportsBostonServices::Row.import(clean_headers(csv_rows.headers), clean_rows(csv_rows))
        end
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
      }
    end

    private def clean_rows(rows)
      rows.map { |row| row.to_h.values + [id, data_source_id] }
    end

    def post_process
      update(status: 'matching')
      matched = 0
      rows.preload(:enrollment, client: :destination_client).find_in_batches do |batch|
        service_batch = []
        # event_batch = []
        batch.each do |row|
          next unless row.client

          matched += 1
          service_batch << {
            source_id: row.id,
            source_type: row.class.name,
            date: row.date,
            client_id: row.client.destination_client.id,
          }
          # if enrollment.blank?
          #   # custom service for client
          # else
          #   # synthetic referral Event on enrollment
          # end
        end
        GrdaWarehouse::Generic::Service.import(
          service_batch,
          conflict_target: [:source_id, :source_type],
          columns: [:date, :client_id],
        )
        summary << "Matched #{matched} services"
        update(status: 'complete', completed_at: Time.current)
      end
    end

    def most_recent_on_s3
      files = []
      # Returns oldest first
      config.s3.fetch_key_list(prefix: config.s3_prefix).each do |entry|
        files << entry if entry.include?(config.s3_prefix)
      end
      return nil if files.empty?

      # Fetch the most recent file
      file = files.last
      return file if file.present?

      nil
    end
  end
end
