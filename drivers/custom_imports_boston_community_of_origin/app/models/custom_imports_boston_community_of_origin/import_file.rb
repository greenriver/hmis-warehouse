###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomImportsBostonCommunityOfOrigin
  class ImportFile < ::GrdaWarehouse::CustomImports::ImportFile
    after_initialize do
      self.data_source_id ||= config&.data_source&.id
    end

    has_many :rows

    def self.description
      'Boston Custom Community of Origins'
    end

    def detail_path
      [:custom_imports, :boston_community_of_origins, :file]
    end

    def filename
      file
    end

    def import!(force = false)
      return unless check_hour || force

      start_import
      fetch_and_load
      complete_import
    end

    # Override CSV load so that we can upsert.
    def load_csv(file)
      batch_size = 10_000
      loaded_rows = 0

      headers = clean_headers(file.first)
      file.drop(1).each_slice(batch_size) do |lines|
        loaded_rows += lines.count
        cleaned_headers = headers.reject { |h| h == 'do_not_import' }
        cleaned_rows = clean_rows(headers, lines)
        cleaned_rows = cleaned_rows.map { |row| row << true } # Mark imported rows as dirty
        cleaned_rows = cleaned_rows.map { |row| ["#{row[0]}_#{row[2]}", row[1..]].flatten }
        rows.klass.import!(
          cleaned_headers,
          cleaned_rows,
          on_duplicate_key_update: {
            conflict_target: [:unique_id],
            columns: cleaned_headers,
          },
        )
      end
      summary << "Loaded #{loaded_rows} rows"
    end

    private def clean_headers(headers)
      headers[0] = 'row_number'
      headers << 'import_file_id'
      headers << 'data_source_id'
      headers << 'dirty'
      headers.map do |h|
        header_lookup[h] || h
      end
    end

    private def header_lookup
      {
        'row_number' => 'do_not_import',
        'Unique Identifier' => 'unique_id',
        'Personal ID' => 'personal_id',
        'Client Full Name' => 'do_not_import', # Use warehouse name
        'Enrollment ID' => 'enrollment_id',
        'Project Start Date' => 'do_not_import', # Use enrollment start date
        'Project Exit Date' => 'do_not_import', # Use enrollment exit date
        'Program ID' => 'do_not_import', # Use enrollment project id
        'Name' => 'do_not_import', # Use project name
        'City' => 'city',
        'State' => 'state',
        'Zip Code' => 'zip_code',
        'How long has it been since you stayed in that community?' => 'length_of_time',
        'Reporting Period Start Date' => 'do_not_import',
        'Reporting Period End Date' => 'do_not_import',
        'Client geolocation Location' => 'geolocation_location',
      }
    end

    def self.process_locations
      rows = Row.where(dirty: true)
      rows.preload(enrollment: :project, client: :destination_client).find_in_batches do |batch|
        location_batch = []
        batch.each do |row|
          next unless row.client.present? && row.enrollment.present?

          lat, lon = location(row)
          location_batch << row.build_client_location(
            client_id: row.client.destination_client.id,
            located_on: contact_date(row),
            lat: lat,
            lon: lon,
            collected_by: row.enrollment.project&.name,
          )
        end
        # Remove any pre-existing locations
        ::ClientLocationHistory::Location.where(source_id: location_batch.map(&:source_id), source_type: rows.klass.name).delete_all
        ::ClientLocationHistory::Location.import!(location_batch)
      end

      rows.update_all(dirty: false)
    end

    def self.contact_date(row)
      # We know that they were somewhere else before the enrollment, so use that date?
      row.enrollment.EntryDate

      # If we need better data, collected_on is the enrollment approximate date homeless (DateToStreetESSH)
      # return nil unless row.collected_on.present?
      #
      # case row.length_of_time
      # when 'Less than 1 week ago'
      #   collected_on - 1.week.ago
      # when 'About 1 month ago'
      #   collected_on - 1.months.ago
      # when 'Less than 6 months ago'
      #   collected_on - 5.months.ago
      # when 'More than 6 months ago'
      #   collected_on - 11.months.ago
      # when 'More than 1 year ago'
      #   collected_on - 13.months.ago
      # else
      #
      # end
    end

    # Geolocate based on available information.
    # Search order: provided geolocation, zip_code, city, and then state
    #
    # @return [Array<Float>] [latitude, longitude] if location found, nil otherwise
    def self.location(row)
      if row.geolocation_location.present?
        # TODO decode geolocation_location
      end

      if row.zip_code.present?
        clean_zipcode = row.zip_code.strip.delete('^0-9')
        return ::GrdaWarehouse::Place.lookup_lat_lon(postalcode: clean_zipcode)
      end
      # Include the state in the city search, if we have it
      return ::GrdaWarehouse::Place.lookup_lat_lon(city: row.city, state: row.state.presence) if row.city.present?
      return ::GrdaWarehouse::Place.lookup_lat_lon(state: row.state) if row.state.present?

      [nil, nil]
    end
  end
end
