###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Fy2020
  class DqClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_dq_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    has_many :hud_report_dq_living_situations, class_name: 'HudDataQualityReport::Fy2020::DqLivingSituation', foreign_key: :hud_report_dq_client_id, inverse_of: :dq_client

    # Hide ID, move destination_client_id, and name to the front
    def self.detail_headers
      special = ['destination_client_id', 'personal_id', 'first_name', 'last_name']
      remove = ['id', 'client_id', 'created_at', 'updated_at', 'gender']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        label = case h
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
