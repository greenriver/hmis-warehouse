###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Filter::HouseholdFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope.joins(:enrollments).
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_open_on_date)).
      yield_self(&method(:with_hoh_age_range)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) do
      if input.status.present?
        ids = []

        ids += scope.merge(Hmis::Hud::Enrollment.active).pluck(:id) if input.status.include?('ACTIVE')
        ids += scope.merge(Hmis::Hud::Enrollment.incomplete).pluck(:id) if input.status.include?('INCOMPLETE')
        ids += scope.exited.pluck(:id) if input.status.include?('EXITED')

        return scope.where(id: ids)
      end

      scope
    end
  end

  def with_open_on_date(scope)
    with_filter(scope, :open_on_date) { scope.merge(Hmis::Hud::Enrollment.open_on_date(input.open_on_date)) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) { scope.merge(Hmis::Hud::Enrollment.with_project_type(input.project_type)) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.merge(Hmis::Hud::Enrollment.matching_search_term(input.search_term)) }
  end

  def with_hoh_age_range(scope)
    with_filter(scope, :hoh_age_range) do
      start_age = input.hoh_age_range.begin
      end_age = input.hoh_age_range.end
      scope.merge(Hmis::Hud::Enrollment.heads_of_households.in_age_group(start_age: start_age, end_age: end_age))
    end
  end
end
