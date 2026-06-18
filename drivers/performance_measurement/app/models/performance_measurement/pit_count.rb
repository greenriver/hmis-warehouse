###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
