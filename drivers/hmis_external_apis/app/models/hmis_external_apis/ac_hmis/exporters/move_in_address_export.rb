###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::AcHmis::Exporters
  class MoveInAddressExport
    include ::HmisExternalApis::AcHmis::Exporters::CsvExporter

    def run!
      Rails.logger.info 'Generating content of Move-in Address export'

      write_row(columns)
      total = move_in_addresses.count

      Rails.logger.error "There are #{total} addresses to export. That doesn't look right" if total < 10

      move_in_addresses.find_each.with_index do |address, i|
        Rails.logger.info "Processed #{i} of #{total}" if (i % 1000).zero?

        warehouse_id = address.client.warehouse_id
        next unless warehouse_id.present? # Client doesn't have a destination client ID yet. Skip since it wont be in Client.csv anyway.

        values = [
          warehouse_id, # PersonalID matching HMIS CSV export
          address.enrollment.id, # EnrollmentID matching HMIS CSV export
          address.line1,
          address.line2,
          address.city,
          address.state,
          address.postal_code,
        ]
        write_row(values)
      end
    end

    private

    def columns
      ['PersonalID', 'EnrollmentID', 'AddressLine1', 'AddressLine2', 'City', 'State', 'ZipCode']
    end

    def move_in_addresses
      Hmis::Hud::CustomClientAddress.where(data_source: data_source).
        move_in.
        joins(:enrollment).
        merge(Hmis::Hud::Enrollment.not_in_progress). # drop WIP Enrollments, which won't be present in Enrollment.csv export
        preload(:enrollment, client: :warehouse_client_source). # preload to get client destination id
        distinct
    end
  end
end
