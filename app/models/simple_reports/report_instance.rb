###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimpleReports
  class ReportInstance < GrdaWarehouseBase
    acts_as_paranoid
    self.table_name = 'simple_report_instances'

    belongs_to :user, optional: true
    has_many :report_cells

    scope :viewable_by, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    def universe
      report_cells.universe.first_or_create # There can only be one universe for a simple report
    end

    def cell(cell_name)
      report_cells.where(name: cell_name).first
    end

    def completed?
      status == 'completed'
    end

    def key_for_display(key)
      key.humanize
    end

    def value_for_display(_key, value)
      value
    end
  end
end
