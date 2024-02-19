###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class PitCount < GrdaWarehouseBase
    self.table_name = :coc_pit_counts
    acts_as_paranoid

    belongs_to :goal

    def total_count
      [unsheltered, sheltered].compact.sum
    end
  end
end
