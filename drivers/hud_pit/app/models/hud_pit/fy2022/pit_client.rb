###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Fy2022
  class PitClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_pit_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :source_client, class_name: 'GrdaWarehouse::Hud::Client', foreign_key: :client_id

    delegate :PersonalID, to: :source_client, allow_nil: true

    # Hide ID and timestamps, move identifying info to the front
    def self.detail_headers
      special = ['destination_client', 'first_name', 'last_name', 'PersonalID']
      remove = ['id', 'created_at', 'updated_at', 'destination_client_id']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        title = case h
        when 'destination_client'
          'Warehouse Client ID'
        when 'client_id'
          'Warehouse Source Client ID'
        when 'PersonalID'
          'Personal ID'
        when 'hoh_age'
          'HoH Age'
        else
          h.humanize
        end
        [h, title]
      end.to_h
    end

    def self.detail_headers_for_export
      return detail_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      detail_headers.except('first_name', 'last_name', 'dob', 'ssn')
    end
  end
end
