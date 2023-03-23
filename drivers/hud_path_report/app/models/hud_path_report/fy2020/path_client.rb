###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Fy2020
  class PathClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_path_clients'

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    def self.detail_headers
      special = ['destination_client_id', 'client_id', 'personal_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        label = case h
        when 'client_id'
          'Warehouse Source Client ID'
        when 'destination_client_id'
          'Warehouse Client ID'
        when 'personal_id'
          'HMIS Personal ID'
        else
          h.humanize
        end
        [h, label]
      end.to_h
    end

    def self.detail_headers_for_export
      return detail_headers if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

      detail_headers.except('first_name', 'last_name', 'dob', 'ssn')
    end
  end
end
