###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module MaReports::MonthlyPerformance
  class Enrollment < GrdaWarehouseBase
    self.table_name = :ma_monthly_performance_enrollments
    acts_as_paranoid

    has_many :simple_reports_universe_members, inverse_of: :universe_membership, class_name: 'SimpleReports::UniverseMember', foreign_key: :universe_membership_id

    scope :open_between, ->(range) do
      a_t = arel_table
      entry_date = a_t[:entry_date]
      exit_date = a_t[:exit_date]
      # Currently does not count as an overlap if one starts on the end of the other
      where(exit_date.gteq(range.first).or(exit_date.eq(nil)).and(entry_date.lteq(range.last)))
    end
  end
end
