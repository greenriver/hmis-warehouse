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

      # Start of the 60-day window during which this year's Annual should be performed. (Anniversary - 30 days)
      start_date = Arel.sql <<~SQL
        make_date(
          extract(year from current_date)::integer,
          extract(month from "EntryDate")::integer,
          1
        ) - interval '30 days' + "interval"((extract(day from "EntryDate")::integer - 1) || ' days')
      SQL

      # Start of the 60-day window during which _last_ year's Annual should have been performed
      last_start_date = Arel.sql <<~SQL
        make_date(
          extract(year from current_date)::integer,
          extract(month from "EntryDate")::integer,
          1
        ) - interval '30 days' + "interval"((extract(day from "EntryDate")::integer - 1) || ' days') - interval '1 year'
      SQL

      # SQL-ized version of the logic here: drivers/hmis/app/models/hmis/reminders/reminder_generator.rb#annual_assessment_reminder
      scope.
        joins(:household).
        joins(
          e_t.
          join(cas_t, Arel::Nodes::OuterJoin).
          on(
            cas_t[:enrollment_id].eq(e_t[:enrollment_id]).
            and(cas_t[:data_collection_stage]).eq(5).
            and(cas_t[:wip]).eq(false),
          ).join_sources,
        ).
        # Earliest entry was more than a year ago
        where(hh_t[:earliest_entry].lteq(Date.today - 11.months)).
        # Household is not exited
        where(hh_t[:latest_exit].eq(nil)).
        where(
          # This enrollment has not had any annual assessments
          cas_t[:assessment_date].eq(nil).
          # OR an annual assessment is now due for this year and hasn't been done yet
          or(start_date.lteq(Date.today).and(cas_t[:assessment_date].lt(start_date))).
          # OR an annual assessment is not due yet for this year but one was not done for last year
          or(start_date.gteq(Date.today).and(cas_t[:assessment_date].lt(last_start_date))),
        ).
        distinct
    end
  end
end
