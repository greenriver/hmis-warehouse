###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudConcerns::Enrollment
  extend ActiveSupport::Concern
  included do
    scope :open_during_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      d_1_start = range.first
      d_1_end = range.last
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      left_outer_joins(:exit).
        where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :open_on_date, ->(date = Date.current) do
      open_during_range(date..date)
    end

    scope :in_project, ->(project_ids) do
      joins(:project).where(p_t[:id].in(project_ids))
    end
  end
end
