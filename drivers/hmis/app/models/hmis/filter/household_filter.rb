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
    with_filter(scope, :statuses) do
      if input.statuses.present?
        ids = []

        ids += scope.merge(Hmis::Hud::Enrollment.active).pluck(:id) if input.statuses.include?('ACTIVE')
        ids += scope.merge(Hmis::Hud::Enrollment.incomplete).pluck(:id) if input.statuses.include?('INCOMPLETE')
        ids += scope.merge(Hmis::Hud::Enrollment.exited).pluck(:id) if input.statuses.include?('EXITED')

        return scope.where(id: ids)
      end

      scope
    end
  end

  def with_open_on_date(scope)
    with_filter(scope, :open_on_date) { scope.merge(Hmis::Hud::Enrollment.open_on_date(input.open_on_date)) }
  end

  def with_project_types(scope)
    with_filter(scope, :project_types) { scope.merge(Hmis::Hud::Enrollment.with_project_type(input.project_types)) }
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) { scope.merge(Hmis::Hud::Enrollment.matching_search_term(input.search_term)) }
  end

  def with_hoh_age_range(scope)
    with_filter(scope, :age_range) { scope.merge(Hmis::Hud::Enrollment.with_age_range(input.age_range)).merge(Hmis::Hud::Enrollment.heads_of_households) }
  end
end
