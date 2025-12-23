###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'roo'

# One-off export for HMIS Clients with MCI Unique ID from an Excel file.
# The file will be used to do a data comparison to investigate the accuracy of the MCI Unique ID assignment.
#
# Usage: AcHmis::ExportClientsMciUnique20251216.new(filename).perform
module AcHmis
  class ExportClientsMciUnique20251216
    attr_reader :file_path
    HEADERS = [
      'MCI_UNIQ_ID',
      'FNAME',
      'LNAME',
      'DOB',
      'SSN',
      'HMIS_ID',
      'WAREHOUSE_ID',
      'MCI_IDS', # pipe-separated list of MCI ID
      'DATE_CLIENT_CREATED', # Date the client was created
      'DATE_MCI_UNIQ_ID_CREATED', # Date the MCI Unique ID was created
      'DATE_MCI_UNIQ_ID_UPDATED', # Date the MCI Unique ID was updated
    ].freeze
    BATCH_SIZE = 1000

    def initialize(file_path)
      @file_path = file_path
    end

    def perform
      Rails.logger.info 'Starting MCI Unique ID client export'

      total_clients = clients_with_mci_unique_ids.count
      Rails.logger.info "Found #{total_clients} clients with MCI Unique IDs to export"

      return if total_clients.zero?

      processed_count = 0

      # Create Excel workbook
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: 'Clients') do |sheet|
          # Write headers
          sheet.add_row(HEADERS)

          # Process clients in batches
          clients_with_mci_unique_ids.find_in_batches(batch_size: BATCH_SIZE) do |batch|
            Rails.logger.info "Processing batch #{(processed_count / BATCH_SIZE) + 1} (#{processed_count} of #{total_clients} clients)"

            batch.each do |client|
              row_data = build_row_data(client)
              sheet.add_row(row_data)
              processed_count += 1
            end

            # Force garbage collection every few batches to manage memory
            GC.start if (processed_count % (BATCH_SIZE * 5)).zero?
          end
        end

        # Save the file
        package.serialize(file_path)
      end
      Rails.logger.info "Export completed. Processed #{processed_count} clients. File saved to: #{file_path}"
    end

    private

    def clients_with_mci_unique_ids
      Hmis::Hud::Client.
        where(data_source: data_source).
        joins(:ac_hmis_mci_unique_id).
        joins(:warehouse_client_source).
        preload(:ac_hmis_mci_unique_id, :warehouse_client_source, :ac_hmis_mci_ids)
    end

    def build_row_data(client)
      mci_unique_id = client.ac_hmis_mci_unique_id.value
      warehouse_id = client.warehouse_client_source.destination_id
      mci_ids = client.ac_hmis_mci_ids.map(&:value)

      [
        mci_unique_id,
        client.first_name,
        client.last_name,
        client.dob&.strftime('%Y-%m-%d'),
        client.ssn,
        client.id, # HMIS_ID
        warehouse_id, # WAREHOUSE_ID
        mci_ids.join('|'), # MCI_IDS - pipe-separated list of MCI IDs
        client.date_created&.strftime('%Y-%m-%d %H:%M:%S'), # DATE_CLIENT_CREATED
        client.ac_hmis_mci_unique_id.created_at&.strftime('%Y-%m-%d %H:%M:%S'), # DATE_MCI_UNIQ_ID_CREATED
        client.ac_hmis_mci_unique_id.updated_at&.strftime('%Y-%m-%d %H:%M:%S'), # DATE_MCI_UNIQ_ID_UPDATED
      ]
    end

    def data_source
      @data_source ||= HmisExternalApis::AcHmis.data_source
    end
  end
end
