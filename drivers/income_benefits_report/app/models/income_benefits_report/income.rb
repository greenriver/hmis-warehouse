###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    belongs_to :income_benefits, class_name: 'GrdaWarehouse::Hud::IncomeBenefit', optional: true

    # Provides a means of differentiating report from comparison period
    scope :date_range, ->(range_string) do
      where(date_range: range_string)
    end

    scope :earlier, -> do
      where(stage: :earlier)
    end

    scope :later, -> do
      where(stage: :later)
    end

    scope :with_earned_income, -> do
      where(Earned: 1)
    end

    scope :with_any_income, -> do
      where(IncomeFromAnySource: 1)
    end

    scope :with_unearned_income, -> do
      where(IncomeFromAnySource: 1).where.not(Earned: 1)
    end
  end
end
