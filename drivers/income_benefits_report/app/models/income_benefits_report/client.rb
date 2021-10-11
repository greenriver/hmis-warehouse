###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This report runs all calculations against the most-recently started enrollment
# that matches the filter scope for a given client
module IncomeBenefitsReport
  class Client < GrdaWarehouseBase
    self.table_name = 'income_benefits_report_clients'
    belongs_to :report, optional: true
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    has_many :incomes
    has_one :earlier_income_record, -> { earlier }, class_name: 'IncomeBenefitsReport::Income'
    has_one :later_income_record, -> { later }, class_name: 'IncomeBenefitsReport::Income'

    scope :date_range, ->(range_string) do
      where(date_range: range_string)
    end

    scope :heads_of_household, -> do
      where(head_of_household: true)
    end

    scope :adults, -> do
      where(arel_table[:age].gteq(18))
    end

    scope :children, -> do
      where(arel_table[:age].lt(18))
    end

    scope :leavers, ->(date) do
      where(arel_table[:exit_date].lt(date))
    end

    scope :stayers, ->(date) do
      where(arel_table[:exit_date].eq(nil).or(arel_table[:exit_date].gteq(date)))
    end
  end
end
