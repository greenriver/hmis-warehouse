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
      if input.household_tasks&.include?('ANNUAL_DUE')
        entry_anniversary = Arel.sql('make_date(extract(year from current_date)::integer, extract(month from "EntryDate")::integer, extract(day from "EntryDate")::integer)')
        start_date = Arel.sql('make_date(extract(year from current_date)::integer, extract(month from "EntryDate")::integer, extract(day from "EntryDate")::integer) - interval \'30 days\'')

        assessment_ids = Hmis::Hud::CustomAssessment.
          where(
            enrollment_id: scope.pluck(:enrollment_id),
            data_source_id: scope.joins(:project).pluck(p_t[:data_source_id]).uniq,
            data_collection_stage: 5,
            wip: false,
          ).
          pluck(:id)

        # SQL-ized version of the logic here: drivers/hmis/app/models/hmis/reminders/reminder_generator.rb#annual_assessment_reminder
        scope = scope.
          left_outer_joins(:exit).
          joins(e_t.join(cas_t, Arel::Nodes::OuterJoin).on(cas_t[:enrollment_id].eq(e_t[:enrollment_id]).and(cas_t[:id]).in(assessment_ids)).join_sources).
          # Include anything where the entry date is outside of the year window
          where(e_t[:entry_date].lteq(Date.today - 1.year + 30.days)).
          # Include anything that isn't exited, or was exited after the entry anniversary
          where(ex_t[:exit_date].eq(nil).or(ex_t[:exit_date].gt(entry_anniversary))).
          # Include anything that was last assessed before the anniversary start date minus window
          where(cas_t[:assessment_date].eq(nil).or(cas_t[:assessment_date].lt(start_date)))
      end

      scope
    end
  end
end
