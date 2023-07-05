###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Enrollment < GrdaWarehouseBase
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :report
    belongs_to :source_enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', foreign_key: :enrollment_id
    has_one :source_client, through: :source_enrollment, class_name: 'GrdaWarehouse::Hud::Client'
    has_one :source_project, through: :source_enrollment, class_name: 'GrdaWarehouse::Hud::Project'
    has_many :events
  end
end
