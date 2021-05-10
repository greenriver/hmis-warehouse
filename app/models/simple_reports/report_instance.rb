###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SimpleReports
  class ReportInstance < GrdaWarehouseBase
    acts_as_paranoid
    self.table_name = 'simple_report_instances'

    belongs_to :user
    has_many :report_cells

    def initialize(options)
      super

      self.options = options
    end

    def universe
      report_cells.universe.first # There can only be one universe for a simple report
    end

    def universe= (members)
      report_cells.build.add_members(members)
    end
  end
end