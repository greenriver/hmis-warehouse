###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# a view into enrollments
module GrdaWarehouse::Report
  class Enrollment < Base
    self.table_name = :report_enrollments
    include ArelHelper

    belongs :demographic # source client
    belongs :client
    many :health_and_dvs
    many :disabilities
    many :income_benefits
    many :employment_educations
    one :exit

    scope :open_during_range, ->(range) do
      e_t = arel_table
      ex_t = GrdaWarehouse::Report::Exit.arel_table
      d_1_start = range.start
      d_1_end = range.end
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      # Currently does not count as an overlap if one starts on the end of the other
      left_outer_joins(:exit).
        where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end)))
    end
  end
end
