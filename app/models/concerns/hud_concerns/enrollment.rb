###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudConcerns::Enrollment
  extend ActiveSupport::Concern
  included do
    # NOTE: this is fairly computationally expensive if you run it in a loop (it needs to
    # run a table scan on Enrollment.)  Each call is relatively fast, but you'll
    # probably want to pluck ids and batch fetch by id batches if you are running it more
    # than a handful of times
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

    # enrollments what were open on the date in question, including those that had an ExitDate on `on_date`
    scope :ongoing, ->(on_date: Date.current) do
      open_during_range(on_date..on_date)
    end

    scope :open_on_date, ->(date = Date.current) do
      open_during_range(date..date)
    end

    scope :in_project, ->(project_ids) do
      joins(:project).where(p_t[:id].in(project_ids))
    end

    def open_during_range?(range)
      self.EntryDate <= range.last && (exit&.ExitDate.blank? || exit.ExitDate > range.first)
    end

    def open_on_date?(date)
      open_during_range?(date..date)
    end

    def self.invalidate_processing!
      update_all(processed_as: nil, processed_hash: nil)
    end

    def invalidate_processing!
      # use update_columns to avoid stale object errors when this method is called from Service after_commit hooks
      with_locking_disabled do
        update_columns(processed_as: nil, processed_hash: nil)
      end
    end
  end
end
