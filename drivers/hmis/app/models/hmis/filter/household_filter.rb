###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::HouseholdFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    # we aren't joining to enrollments to avoid duplicate household records
    scope.
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_open_on_date)).
      yield_self(&method(:with_hoh_age_range)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:with_assigned_staff))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) do
      if input.status.present?
        return scope.active if input.status == ['ACTIVE'] || input.status.sort == ['ACTIVE', 'INCOMPLETE'].sort
        return scope if input.status.sort == ['ACTIVE', 'INCOMPLETE', 'EXITED'].sort

        ids = []
        # pulling down client ids is not optimal here
        ids += scope.active.pluck(:id) if input.status.include?('ACTIVE')
        ids += scope.in_progress.pluck(:id) if input.status.include?('INCOMPLETE')
        ids += scope.exited.pluck(:id) if input.status.include?('EXITED')

        return scope.where(id: ids)
      end

      scope
    end
  end

  def with_open_on_date(scope)
    with_filter(scope, :open_on_date) { scope.open_on_date(input.open_on_date) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) { scope.with_project_type(input.project_type) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) do
      e_t = Hmis::Hud::Enrollment.arel_table
      hh_t = Hmis::Hud::Household.arel_table
      scope.where(
        Hmis::Hud::Enrollment.
          matching_search_term(input.search_term).
          where(
            e_t[:data_source_id].eq(hh_t[:data_source_id]).and(e_t[:HouseholdID].eq(hh_t[:HouseholdID])),
          ).arel.exists,
      )
    end
  end

  def with_hoh_age_range(scope)
    with_filter(scope, :hoh_age_range) do
      e_t = Hmis::Hud::Enrollment.arel_table
      hh_t = Hmis::Hud::Household.arel_table

      start_age = input.hoh_age_range.begin
      end_age = input.hoh_age_range.end

      scope.where(
        Hmis::Hud::Enrollment.
          heads_of_households.in_age_group(start_age: start_age, end_age: end_age).
          where(
            e_t[:data_source_id].eq(hh_t[:data_source_id]).and(e_t[:HouseholdID].eq(hh_t[:HouseholdID])),
          ).arel.exists,
      )
    end
  end

  def with_assigned_staff(scope)
    with_filter(scope, :assigned_staff) do
      sa_t = Hmis::StaffAssignment.arel_table
      scope.joins(:staff_assignments).where(sa_t[:user_id].eq(input.assigned_staff))
    end
  end
end
