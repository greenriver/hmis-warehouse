###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PreloadCoverageHelpers
  # How many unrestricted clients a list must contain for a missing
  # preload_client_dependencies call to raise PreloadMissError. Restricted clients
  # never record a miss, so all of these must be unrestricted.
  def preload_miss_client_count
    GrdaWarehouse::AuthPolicies::PreloadMissTracker::THRESHOLD + 2
  end

  # Every cell value on the first sheet of an xlsx body.
  def xlsx_cell_values(response_or_bytes)
    bytes = response_or_bytes.respond_to?(:body) ? response_or_bytes.body : response_or_bytes
    file = Tempfile.new(['preload_coverage', '.xlsx'])
    file.binmode
    file.write(bytes)
    file.close
    sheet = Roo::Excelx.new(file.path).sheet(0)
    return [] if sheet.first_row.nil?

    (sheet.first_row..sheet.last_row).flat_map { |i| sheet.row(i) }
  ensure
    file&.unlink
  end
end
