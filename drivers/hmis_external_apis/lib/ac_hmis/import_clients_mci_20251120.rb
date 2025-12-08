###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'roo'

# One-off import for HMIS Clients with MCI ID & MCI Unique ID from an Excel file.
# Expected headers: MCI_ID, MCI_UNIQ_ID, FNAME, LNAME, DOB
#
# Import logic:
# 1. Look up client by MCI Unique ID. If found, skip (do not update Name/DOB, do not add MCI ID).
# 2. If not found, look up client by MCI ID. If found, ensure MCI Unique ID matches (do not update Name/DOB).
# 3. If not found by either, create new client with provided name and DOB, and associate both MCI ID and MCI Unique ID.
#
# Usage: AcHmis::ImportClientsMci20251120.new(filename, dry_run: true).perform
module AcHmis
  class ImportClientsMci20251120
    attr_reader :file_path, :dry_run

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
    end

    EXPECTED_HEADERS = ['MCI_ID', 'MCI_UNIQ_ID', 'FNAME', 'LNAME', 'DOB'].freeze
    BATCH_SIZE = 1000

    def perform
      puts "Starting MCI import from #{file_path}"
      puts '== DRY RUN MODE ==' if dry_run

      @stats = {
        skipped_mci_unique_id_found: 0,
        skipped_mci_id_found: 0,
        mci_unique_id_mismatch: 0,
        created: 0,
        errors: [],
        warnings: [],
      }

      # Initialize batch collections
      @clients_to_create = {} # {row_number => Client object}
      @mci_ids_to_create = {} # {row_number => mci_id value}
      @mci_unique_ids_to_create = {} # {row_number => mci_unique_id value}

      begin
        Hmis::Hud::Base.transaction do
          read_and_process_file

          # Perform bulk imports after processing all rows
          unless dry_run
            bulk_create_clients! if @clients_to_create.any?
            bulk_create_external_ids! if @mci_ids_to_create.any? || @mci_unique_ids_to_create.any?
            # Trigger duplicate identification once at the end
            Hmis::Hud::Client.warehouse_identify_duplicate_clients if @clients_to_create.any?
          end

          # Rollback if there were any errors (warnings don't prevent import)
          if @stats[:errors].any?
            error_count = @stats[:errors].length
            raise "Import failed with #{error_count} error(s). Transaction rolled back."
          end
        end
      rescue StandardError => e
        # Transaction was rolled back, but we still want to print the summary
        puts "\nERROR: #{e.message}"
      end

      print_summary
    end

    private

    def read_and_process_file
      xlsx = Roo::Excelx.new(file_path)
      sheet = xlsx.sheet(0)

      # Read headers from first row
      headers = sheet.row(1).map(&:to_s).map(&:strip)
      validate_headers(headers)

      # Create header index map
      header_map = headers.each_with_index.to_h

      # Validate uniqueness of MCI Unique IDs before processing
      validate_unique_ids(sheet, header_map)

      # Process each data row (starting from row 2, since row 1 is headers)
      row_number = 1
      sheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
        row_number += 1
        process_row(row, header_map, row_number)
      end
    end

    def validate_headers(headers)
      missing_headers = EXPECTED_HEADERS - headers
      return unless missing_headers.any?

      raise "Missing required headers: #{missing_headers.join(', ')}"
    end

    def validate_unique_ids(sheet, header_map)
      mci_unique_ids_seen = {}

      row_number = 1
      sheet.each_row_streaming(offset: 1, pad_cells: true) do |row|
        row_number += 1
        mci_unique_id = get_cell_value(row, header_map['MCI_UNIQ_ID'])

        # Skip empty rows
        next if mci_unique_id.blank?

        # Track MCI Unique ID occurrences
        mci_unique_id_key = mci_unique_id.to_s
        if mci_unique_ids_seen.key?(mci_unique_id_key)
          error_msg = "Duplicate MCI Unique ID found: #{mci_unique_id} appears in rows #{mci_unique_ids_seen[mci_unique_id_key]} and #{row_number}"
          @stats[:errors] << error_msg
          puts "ERROR: #{error_msg}"
        else
          mci_unique_ids_seen[mci_unique_id_key] = row_number
        end
      end

      # Raise error if duplicates found
      return unless @stats[:errors].any?

      raise 'File validation failed: Found duplicate MCI IDs or MCI Unique IDs in the file'
    end

    def process_row(row, header_map, row_number)
      mci_id = get_cell_value(row, header_map['MCI_ID'])
      mci_unique_id = get_cell_value(row, header_map['MCI_UNIQ_ID'])
      first_name = get_cell_value(row, header_map['FNAME'])
      last_name = get_cell_value(row, header_map['LNAME'])
      dob_str = get_cell_value(row, header_map['DOB'])

      # Skip empty rows
      return if mci_id.blank? && mci_unique_id.blank? && first_name.blank? && last_name.blank?

      # Validate required fields
      if mci_id.blank? || mci_unique_id.blank? || (first_name.blank? && last_name.blank?)
        error_msg = "Row #{row_number}: Missing required fields (MCI_ID, MCI_UNIQ_ID, FNAME, LNAME)"
        @stats[:errors] << error_msg
        puts "ERROR: #{error_msg}"
        return
      end

      # Normalize name casing (convert all caps to proper case)
      first_name = normalize_name(first_name)
      last_name = normalize_name(last_name)

      # Parse DOB
      dob = parse_dob(dob_str) if dob_str.present?
      if dob_str.present? && dob.blank?
        error_msg = "Row #{row_number}: Invalid DOB format: #{dob_str}"
        @stats[:errors] << error_msg
        puts "ERROR: #{error_msg}"
        return
      end

      # Step 1: Look up by MCI Unique ID
      # If found, skip - do not update Name/DOB, do not add MCI ID
      client_id = find_client_id_by_mci_unique_id(mci_unique_id)
      if client_id.present?
        # puts "Row #{row_number}: Skipped - Client found by MCI Unique ID #{mci_unique_id} (Client ID: #{client_id})"
        @stats[:skipped_mci_unique_id_found] += 1
        return
      end

      # Step 2: Look up by MCI ID
      # If found, ensure MCI Unique ID matches - do not update Name/DOB
      clients = find_clients_by_mci_id(mci_id)
      if clients.any?
        # Check if there are multiple clients with the same MCI ID
        if clients.length > 1
          client_ids = clients.map(&:id).join(', ')
          error_msg = "Row #{row_number}: Multiple clients found with MCI ID #{mci_id} (Client IDs: #{client_ids})"
          @stats[:errors] << error_msg
          puts "ERROR: #{error_msg}"
          return
        end

        client = clients.sole
        existing_mci_unique_id_record = client.ac_hmis_mci_unique_id
        existing_mci_unique_id = existing_mci_unique_id_record&.value
        # Perform any necessary updates to the MCI Unique ID:
        # Case 1: MCI Unique ID exists but doesn't match the value in the file. Update it to match the file, and log a warning.
        # Case 2: MCI Unique ID does not exist. Add it to the client.
        # Case 3: MCI Unique ID exists and matches the value in the file. Do nothing.
        if existing_mci_unique_id.present? && existing_mci_unique_id != mci_unique_id
          @stats[:mci_unique_id_mismatch] += 1
          base_msg = "Row #{row_number}: Client##{client.id} found by MCI ID #{mci_id} but has different MCI Unique ID (#{existing_mci_unique_id} vs #{mci_unique_id})."
          # If MCI Unique ID on the client was added in the past 6 months, don't update it. Retain the existing MCI Unique ID.
          if existing_mci_unique_id_record.updated_at > 6.months.ago
            warning_msg = "#{base_msg} Existing MCI Unique ID was added in the past 6 months. Skipping."
            @stats[:warnings] << warning_msg
            puts "WARNING: #{warning_msg}"
            return
          end

          # Safety Check: fuzzy identity match before linking this client to the specific MCI Unique ID (and un-linking the existing MCI Unique ID)
          unless identity_match?(client, first_name, last_name, dob)
            warning_msg = "#{base_msg} IDENTITY MISMATCH - Name/DOB differs significantly. File: #{first_name} #{last_name} (#{dob}), DB: #{client.first_name} #{client.last_name} (#{client.dob}). Skipping."
            @stats[:warnings] << warning_msg
            puts "WARNING: #{warning_msg}"
            return
          end

          warning_msg = "#{base_msg} Identity match confirmed, updating MCI Unique ID to match file."
          @stats[:warnings] << warning_msg
          puts "WARNING: #{warning_msg}"

          # Update the MCI Unique ID to match what's in the file
          if dry_run
            puts "[DRY RUN] Row #{row_number}: Would update MCI Unique ID from #{existing_mci_unique_id} to #{mci_unique_id} for client (Client ID: #{client.id})"
          else
            update_mci_unique_id(client, mci_unique_id)
            puts "Row #{row_number}: Updated MCI Unique ID from #{existing_mci_unique_id} to #{mci_unique_id} for client (Client ID: #{client.id})"
          end
        elsif existing_mci_unique_id.blank?
          # Add MCI Unique ID if missing (to ensure it matches what's on the row)
          if dry_run
            puts "[DRY RUN] Row #{row_number}: Would add MCI Unique ID #{mci_unique_id} to existing client (Client ID: #{client.id}, MCI ID: #{mci_id})"
          else
            create_mci_unique_id(client, mci_unique_id)
            puts "Row #{row_number}: Added MCI Unique ID #{mci_unique_id} to existing client (Client ID: #{client.id}, MCI ID: #{mci_id})"
          end
        else
          # Matching case
          puts "Row #{row_number}: Skipped - Client found by MCI ID #{mci_id} with matching MCI Unique ID (Client ID: #{client.id})"
        end
        @stats[:skipped_mci_id_found] += 1
        return
      end

      # Step 3: Collect new client for bulk creation
      if dry_run
        puts "[DRY RUN] Row #{row_number}: Would create new client: MCI ID: #{mci_id}, MCI Unique ID: #{mci_unique_id}"
      else
        collect_client_for_bulk_create(first_name, last_name, dob, mci_id, mci_unique_id, row_number)
      end
      @stats[:created] += 1
    end

    def get_cell_value(row, index)
      return nil if index.nil?

      cell = row[index]
      return nil unless cell

      value = cell&.value
      return nil if value.nil?

      # Handle different cell types
      case value
      when Date, Time
        value.to_s
      else
        value.to_s.strip.presence
      end
    end

    def normalize_name(name)
      return nil if name.blank?
      # leave name as-is if it's not all caps
      return name unless name.upcase == name

      # Convert all caps to proper case (Title Case)
      # Handle both spaces and hyphens: "HYPHENATED-NAME" -> "Hyphenated-Name"
      name.to_s.split(/\s+/).map do |word|
        word.split('-').map(&:capitalize).join('-')
      end.join(' ')
    end

    def parse_dob(dob_str)
      return nil if dob_str.blank?

      # Try parsing as date
      Date.parse(dob_str.to_s)
    rescue ArgumentError, TypeError
      # Return nil if date parsing fails, which will be caught by the validation check
      nil
    end

    def mci_unique_id_to_source_client_id
      @mci_unique_id_to_source_client_id ||= begin
        puts 'Building MCI Unique ID lookup map...'
        HmisExternalApis::ExternalId.mci_unique_ids.pluck(:value, :source_id).to_h
      end
    end

    def mci_id_to_source_clients
      @mci_id_to_source_clients ||= begin
        puts 'Building MCI ID lookup map...'
        hash = {}
        HmisExternalApis::ExternalId.mci_ids.find_in_batches(batch_size: 5000) do |batch|
          # Preload clients for this batch
          client_ids = batch.map(&:source_id).compact.uniq
          clients_by_id = Hmis::Hud::Client.where(id: client_ids).index_by(&:id)
          batch.each do |external_id|
            client = clients_by_id[external_id.source_id]
            next unless client # Skip if client was deleted

            key = external_id.value.to_s
            hash[key] ||= []
            hash[key] << client unless hash[key].include?(client)
          end
        end
        hash
      end
    end

    def find_client_id_by_mci_unique_id(mci_unique_id)
      mci_unique_id_to_source_client_id[mci_unique_id.to_s]
    end

    def find_clients_by_mci_id(mci_id)
      mci_id_to_source_clients[mci_id.to_s] || []
    end

    def data_source
      @data_source ||= GrdaWarehouse::DataSource.hmis.first!
    end

    def system_user
      @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def collect_client_for_bulk_create(first_name, last_name, dob, mci_id, mci_unique_id, row_number)
      now = Time.current
      personal_id = SecureRandom.uuid.gsub(/-/, '')

      # Create and initialize a Client object
      client = Hmis::Hud::Client.new(
        PersonalID: personal_id,
        data_source: data_source,
        user: system_user,
        first_name: first_name,
        last_name: last_name,
        dob: dob,
        name_data_quality: 1, # Full name reported
        dob_data_quality: dob.present? ? 1 : 99, # If present, assume Full DOB reported
        veteran_status: 99, # Not collected
        ssn_data_quality: 99, # Not collected
        DateCreated: now,
        DateUpdated: now,
      )

      # Calculate source_hash using the same method as the callback
      client.set_source_hash

      # Store client object and ExternalId values separately
      @clients_to_create[row_number] = client
      @mci_ids_to_create[row_number] = mci_id
      @mci_unique_ids_to_create[row_number] = mci_unique_id
    end

    def bulk_create_clients!
      return if @clients_to_create.empty?

      puts "Bulk creating #{@clients_to_create.length} clients..."

      # Convert Client objects to arrays for import
      clients_array = @clients_to_create.values
      personal_ids = clients_array.map(&:PersonalID)

      # Import in batches - import! updates objects in place with their IDs
      clients_array.each_slice(BATCH_SIZE) do |batch|
        Hmis::Hud::Client.import!(
          batch,
          validate: false,
          timestamps: false, # We're setting DateCreated/DateUpdated manually
        )
      end

      # Reload clients to ensure IDs are set
      created_clients = Hmis::Hud::Client.where(PersonalID: personal_ids, data_source: data_source).index_by(&:PersonalID)

      # Update hash with created clients (now have IDs)
      @clients_to_create.each do |row_number, client|
        created_client = created_clients[client.PersonalID]
        @clients_to_create[row_number] = created_client
        puts "Row #{row_number}: Created new client (Client ID: #{created_client.id}): MCI ID: #{@mci_ids_to_create[row_number]}, MCI Unique ID: #{@mci_unique_ids_to_create[row_number]}"
      end
    end

    def bulk_create_external_ids!
      external_ids = []

      # Build ExternalId records from the stored mappings
      @clients_to_create.each do |row_number, client|
        # Create MCI ID ExternalId
        external_ids << {
          source_type: 'Hmis::Hud::Client',
          source_id: client.id,
          value: @mci_ids_to_create[row_number].to_s,
          namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
          remote_credential_id: mci_creds.id,
        }

        # Create MCI Unique ID ExternalId
        external_ids << {
          source_type: 'Hmis::Hud::Client',
          source_id: client.id,
          value: @mci_unique_ids_to_create[row_number].to_s,
          namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
          remote_credential_id: mci_unique_creds.id,
        }
      end

      return if external_ids.empty?

      puts "Bulk creating #{external_ids.length} ExternalIds..."

      # Import all ExternalIds at once
      HmisExternalApis::ExternalId.import!(
        external_ids,
        validate: false,
      )
    end

    def create_mci_id(client, mci_id)
      HmisExternalApis::ExternalId.create!(
        source: client,
        value: mci_id.to_s,
        namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
        remote_credential: mci_creds,
      )
    end

    def create_mci_unique_id(client, mci_unique_id)
      HmisExternalApis::ExternalId.create!(
        source: client,
        value: mci_unique_id.to_s,
        namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
        remote_credential: mci_unique_creds,
      )
    end

    def update_mci_unique_id(client, mci_unique_id)
      client.ac_hmis_mci_unique_id.update!(value: mci_unique_id.to_s)
    end

    def mci_creds
      @mci_creds ||= GrdaWarehouse::RemoteCredential.where(slug: HmisExternalApis::AcHmis::Mci::SYSTEM_ID).first!
    end

    def mci_unique_creds
      @mci_unique_creds ||= GrdaWarehouse::RemoteCredential.where(slug: HmisExternalApis::AcHmis::DataWarehouseApi::SYSTEM_ID).first!
    end

    # Fuzzy identity matching to verify client matches file data before linking MCI Unique IDs
    # Returns true if names and DOB match (with some tolerance for minor variations)
    def identity_match?(client, first_name, last_name, dob)
      # Normalize names for comparison (case-insensitive, strip whitespace)
      client_first = normalize_for_comparison(client.first_name)
      client_last = normalize_for_comparison(client.last_name)
      file_first = normalize_for_comparison(first_name)
      file_last = normalize_for_comparison(last_name)

      first_name_matches = client_first == file_first
      last_name_matches = client_last == file_last

      # if first AND last names match, consider it a match
      return true if first_name_matches && last_name_matches

      # if neither first NOR last name matches, return early. Not a match.
      return false unless first_name_matches || last_name_matches

      # If DOB is provided in file, it should match the client's DOB year
      if dob.present?
        return false if client.dob.blank? # File has DOB but client doesn't - mismatch

        return client.dob.year == dob.year # Matching same year is sufficient
      end

      # If file doesn't have DOB, we can't verify it, so rely on name match only
      # (This allows matching when DOB is missing from file but present in DB)
      true
    end

    def normalize_for_comparison(name)
      return '' if name.blank?

      # Normalize to lowercase, strip whitespace, and remove extra spaces
      name.to_s.downcase.strip.gsub(/\s+/, ' ')
    end

    def print_summary
      puts 'IMPORT SUMMARY'
      puts "Found by MCI Unique ID (skipped): #{@stats[:skipped_mci_unique_id_found]}"
      puts "Found by MCI ID (skipped or updated): #{@stats[:skipped_mci_id_found]}"
      puts "Created: #{@stats[:created]}"
      puts "Errors: #{@stats[:errors].length}"
      puts "Warnings: #{@stats[:warnings].length}"

      if @stats[:errors].any?
        puts "\nERRORS:"
        @stats[:errors].each { |error| puts "  - #{error}" }
      end

      if @stats[:warnings].any?
        puts "\nWARNINGS:"
        @stats[:warnings].each { |warning| puts "  - #{warning}" }
      end

      @dry_run ? puts("\nDRY RUN MODE - NO CHANGES MADE") : puts("\nIMPORT COMPLETED")
    end
  end
end
