###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Fy2021
  class ProjectCoc < ::GrdaWarehouseBase
    self.table_name = 'hud_report_hic_project_cocs'
    include ::HMIS::Structure::ProjectCoc
    acts_as_paranoid

    has_many :report_project_cocs, as: :universe_membership, dependent: :destroy
    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id

    # Hide ID, move client_id, and name to the front
    def self.detail_headers
      special = ['ProjectCoCID', 'ProjectID']
      remove = ['id', 'created_at', 'updated_at']
      cols = special + (column_names - special - remove)
      cols.map do |h|
        [h, h.humanize]
      end.to_h
    end
  end
end
