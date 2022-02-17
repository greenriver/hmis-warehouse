###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Fy2022
  class Family < ::GrdaWarehouseBase
    self.table_name = 'hud_report_hic_funders'
    include ::HMIS::Structure::Funder
    acts_as_paranoid

    has_many :report_funders, as: :universe_membership, dependent: :destroy
    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
  end
end
