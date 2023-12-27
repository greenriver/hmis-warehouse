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
        or(moved_in)
      # What do we need to do for diversion?  (exit_type Excludable)
      # if the project_id is in the diversion projects, then use the other destinations (or maybe on calculation?)
    end

    # To be considered housed (or "placed") one of the following conditions must be met
    # 1. Client had an exit within the date range and the Exit was to a permanent destination and from a diversion project (specified at run-time)
    # 2. Client has a move-in date during range
    scope :housed_in_range, ->(range, filter:) do
      permanent_diversion_exit(range, filter: filter).
        or(moved_in_in_range(range))
    end

    scope :permanent_diversion_exit, ->(range, filter:) do
      where(exit_type: 'Permanent', exit_date: range, project_id: filter.secondary_project_ids)
    end

    scope :moved_in, -> do
      where.not(move_in_date: nil, project_type: HudUtility2024.project_types_with_move_in_dates)
    end

    scope :moved_in_in_range, ->(range) do
      where(move_in_date: range, project_type: HudUtility2024.project_types_with_move_in_dates)
    end

    scope :homeless, -> do
      where(project_type: HudUtility2024.homeless_project_types)
    end

    scope :returned, -> do
      where.not(return_date: nil)
    end

    scope :hoh, -> do
      where(relationship_to_hoh: 1)
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
