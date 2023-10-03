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
    belongs_to :source_enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', primary_key: :enrollment_id, foreign_key: :enrollment_id
    has_one :source_client, through: :source_enrollment, class_name: 'GrdaWarehouse::Hud::Client'
    has_one :source_project, through: :source_enrollment, class_name: 'GrdaWarehouse::Hud::Project'
    has_many :events

    # exit_type is 'Permanent' or move-in date is present
    scope :housed, -> do
      where(exit_type: 'Permanent').
        or(where.not(move_in_date: nil))
    end

    scope :returned, -> do
      where.not(return_date: nil)
    end

    def intervention
      case project_type
      when 9
        'Emergency Housing Voucher'
      when 13
        'Rapid Rehousing'
      else
        'ERROR'
      end
    end

    def report_start
      report.filter.start_date
    end

    def report_end
      report.filter.end_date
    end

    def enrollment_count
      1
    end

    def move_in_count
      return 1 if move_in_date.present?
    end

    def scaffold_link
      1
    end
  end
end
