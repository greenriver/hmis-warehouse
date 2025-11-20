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
# Usage: AcHmis::OneTimeImportMci20251119.new(filename, dry_run: true).perform
module AcHmis
  class OneTimeImportMci20251119
    attr_reader :file_path, :dry_run

    def initialize(file_path, dry_run: false)
      @file_path = file_path
      @dry_run = dry_run
    end

    EXPECTED_HEADERS = ['MCI_ID', 'MCI_UNIQ_ID', 'FNAME', 'LNAME', 'DOB'].freeze

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

      begin
        Hmis::Hud::Base.transaction do
          read_and_process_file
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

    def process_row(row, header_map, row_number)
      mci_id = get_cell_value(row, header_map['MCI_ID'])
      mci_unique_id = get_cell_value(row, header_map['MCI_UNIQ_ID'])
      first_name = get_cell_value(row, header_map['FNAME'])
      last_name = get_cell_value(row, header_map['LNAME'])
      dob_str = get_cell_value(row, header_map['DOB'])

      # Skip empty rows
      return if mci_id.blank? && mci_unique_id.blank? && first_name.blank? && last_name.blank?

      # Validate required fields
      if mci_id.blank? || mci_unique_id.blank? || first_name.blank? || last_name.blank?
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
      client = find_client_by_mci_unique_id(mci_unique_id)
      if client
        # puts "Row #{row_number}: Skipped - Client found by MCI Unique ID #{mci_unique_id} (Client ID: #{client.id})"
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
        existing_mci_unique_id = client.ac_hmis_mci_unique_id&.value
        # Perform any necessary updates to the MCI Unique ID:
        # Case 1: MCI Unique ID exists but doesn't match the value in the file. Update it to match the file, and log a warning.
        # Case 2: MCI Unique ID does not exist. Add it to the client.
        # Case 3: MCI Unique ID exists and matches the value in the file. Do nothing.
        if existing_mci_unique_id.present? && existing_mci_unique_id != mci_unique_id
          warning_msg = "Row #{row_number}: Client found by MCI ID #{mci_id} but has different MCI Unique ID (#{existing_mci_unique_id} vs #{mci_unique_id}) - updating to match file"
          @stats[:warnings] << warning_msg
          @stats[:mci_unique_id_mismatch] += 1
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

      # Step 3: Create new client
      if dry_run
        puts "[DRY RUN] Row #{row_number}: Would create new client: MCI ID: #{mci_id}, MCI Unique ID: #{mci_unique_id}"
      else
        client = create_client(first_name, last_name, dob, mci_id, mci_unique_id)
        puts "Row #{row_number}: Created new client (Client ID: #{client.id}): MCI ID: #{mci_id}, MCI Unique ID: #{mci_unique_id}"
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

    def find_client_by_mci_unique_id(mci_unique_id)
      Hmis::Hud::Client.first_by_external_id(
        namespace: HmisExternalApis::AcHmis::WarehouseChangesJob::NAMESPACE,
        value: mci_unique_id.to_s,
      )
    end

    def find_clients_by_mci_id(mci_id)
      id_scope = HmisExternalApis::ExternalId.
        where(
          value: mci_id.to_s,
          namespace: HmisExternalApis::AcHmis::Mci::SYSTEM_ID,
          source_type: 'Hmis::Hud::Client',
        )

      Hmis::Hud::Client.where(id: id_scope.select(:source_id)).order(:id).to_a
    end

    def data_source
      @data_source ||= GrdaWarehouse::DataSource.hmis.first!
    end

    def system_user
      @system_user ||= Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def create_client(first_name, last_name, dob, mci_id, mci_unique_id)
      client = Hmis::Hud::Client.create!(
        data_source: data_source,
        user: system_user,
        first_name: first_name,
        last_name: last_name,
        dob: dob,
        name_data_quality: 1, # Full name reported
        dob_data_quality: dob.present? ? 1 : 99, # If present, assume Full DOB reported
        veteran_status: 99, # Not collected
        ssn_data_quality: 99, # Not collected
      )

      # Create MCI ID external ID
      create_mci_id(client, mci_id)

      # Create MCI Unique ID external id
      create_mci_unique_id(client, mci_unique_id)

      client
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

    def print_summary
      puts 'IMPORT SUMMARY'
      puts "# rows found by MCI Unique ID (skipped): #{@stats[:skipped_mci_unique_id_found]}"
      puts "# rows found by MCI ID (skipped or updated): #{@stats[:skipped_mci_id_found]}"
      puts "Clients created: #{@stats[:created]}"
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
