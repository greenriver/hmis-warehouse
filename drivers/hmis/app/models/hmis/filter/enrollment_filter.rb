###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::EnrollmentFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_open_on_date)).
      yield_self(&method(:with_bed_night_on_date)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:with_household_tasks)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) do
      if input.status.present?
        ids = []

        ids += scope.open_excluding_wip.pluck(:id) if input.status.include?('ACTIVE')
        ids += scope.incomplete.pluck(:id) if input.status.include?('INCOMPLETE')
        ids += scope.exited.pluck(:id) if input.status.include?('EXITED')

        return scope.where(id: ids)
      end

      scope
    end
  end

  def with_open_on_date(scope)
    with_filter(scope, :open_on_date) { scope.open_on_date(input.open_on_date) }
  end

  def with_bed_night_on_date(scope)
    with_filter(scope, :bed_night_on_date) { scope.bed_night_on_date(input.bed_night_on_date) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.matching_search_term(input.search_term) }
  end

  def with_household_tasks(scope)
    with_filter(scope, :household_tasks) do
      return scope.all unless input.household_tasks&.include?('ANNUAL_DUE')

      # The SQL statement "interval"((extract(day from "EntryDate")::integer - 1) || ' days') is present to handle leap
      # year dates. That is, if the entry date is 2/29/2020, then just using make_date directly will produce an
      # anniversary date of 2/29/2023, which is invalid. To prevent this, make_date is used to create a date of
      # 2/1/2023, then we add 28 days (29th - 1) to that date to shift it to the proper anniversary date. For any date
      # except for 2/29, this shift should result in the same month and day as the entry date, and for 2/29 it should
      # shift it to 3/1, which is a valid date and avoids the leap year issue.

      anniversary_date = "
        make_date(
          extract(year from current_date)::integer,
          extract(month from \"earliest_entry\")::integer,
          1
        ) + \"interval\"((extract(day from \"earliest_entry\")::integer - 1) || ' days')
      "
      # Due period for the 60-day window during which this year's Annual should be performed
      start_date = Arel.sql("#{anniversary_date} - interval '30 days'")
      end_date = Arel.sql("#{anniversary_date} + interval '30 days'")

      # Due period for the 60-day window during which last year's Annual should have been performed
      last_start_date = Arel.sql("#{anniversary_date} - interval '30 days' - interval '1 year'")
      last_end_date = Arel.sql("#{anniversary_date} + interval '30 days' - interval '1 year'")

      # SQL-ized version of the logic here: drivers/hmis/app/models/hmis/reminders/reminder_generator.rb#annual_assessment_reminder

      this_year_annual_in_range = start_date.lteq(Date.current).and(cas_t[:assessment_date].gteq(start_date).and(cas_t[:assessment_date].lteq(end_date)))
      last_year_annual_in_range = start_date.gteq(Date.current).and(cas_t[:assessment_date].gteq(last_start_date).and(cas_t[:assessment_date].lteq(last_end_date)))

      scope.
        joins(:household).
        # Left outer join with non-WIP Annual Assessments that fall within the relevant Due Period
        joins(
          e_t.
          join(cas_t, Arel::Nodes::OuterJoin).
          on(
            cas_t[:enrollment_id].eq(e_t[:enrollment_id]).
            and(cas_t[:personal_id].eq(e_t[:personal_id])).
            and(cas_t[:data_source_id].eq(e_t[:data_source_id])).
            and(cas_t[:data_collection_stage]).eq(5). # Annual
            and(cas_t[:wip]).eq(false).
            and(this_year_annual_in_range.or(last_year_annual_in_range)),
          ).join_sources,
        ).
        # Earliest entry was more than a year ago
        where(hh_t[:earliest_entry].lteq(Date.today - 11.months)).
        # Household is not exited
        where(hh_t[:latest_exit].eq(nil)).
        # Client entered household before this years anniversary
        where(e_t[:entry_date].lt(Arel.sql(anniversary_date))).
        # Enrollment does not have Annual Assessment in due period
        where(cas_t[:assessment_date].eq(nil)).distinct
    end
  end
end
