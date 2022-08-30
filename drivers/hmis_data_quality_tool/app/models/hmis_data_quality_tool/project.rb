###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Project < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_projects'
    include ArelHelper
    include DqConcern
    acts_as_paranoid

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
  end
end
