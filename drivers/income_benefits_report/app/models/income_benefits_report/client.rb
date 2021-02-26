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
    belongs_to :report
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment'
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project'
    has_one :earlier_income_record, class_name: 'IncomeBenefitsReport::Income', inverse_of: :client
    has_one :later_income_record, class_name: 'IncomeBenefitsReport::Income', inverse_of: :client

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
