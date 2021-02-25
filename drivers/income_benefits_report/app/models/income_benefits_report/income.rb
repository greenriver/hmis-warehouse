###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This report runs all calculations against the most-recently started enrollment
# that matches the filter scope for a given client
module IncomeBenefitsReport
  class Income < GrdaWarehouseBase
    self.table_name = 'income_benefits_report_incomes'
    belongs_to :report, class_name: 'IncomeBenefitsReport::Report'
    belongs_to :client, class_name: 'IncomeBenefitsReport::Client'
    belongs_to :income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit'

    scope :earlier, -> do
      where(stage: :earlier)
    end

    scope :later, -> do
      where(stage: :later)
    end
  end
end
