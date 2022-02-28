###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Fy2022
  class PitClient < ::HudReports::ReportClientBase
    self.table_name = 'hud_report_pit_clients'
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    # Hide ID, move client_id, and name to the front
    def self.detail_headers
      special = ['client_id', 'first_name', 'last_name']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        [h, h.humanize]
      end.to_h
    end
  end
end
