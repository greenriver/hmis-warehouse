###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForCeHomeless < Filters::Criteria::Base
  def applies? = input.coordinated_assessment_living_situation_homeless

  # This needs to work correctly with project type filters, where it adds the
  # potentially additional type of CA, but only if LivingSituation (3.917.1) is
  # of a homeless type (6, 1, 18)
  def apply(scope)
    scope = super(scope)
    p_types = config.project_types.presence || input.project_type_ids
    scope.joins(:enrollment).where(
      arel.she_t[:project_type].in(HudUtility2026.performance_reporting[:ce]).
      and(arel.e_t[:LivingSituation].in(HudUtility2026.homeless_situations(as: :prior))).
      or(arel.she_t[:project_type].in(p_types)),
    )
  end
end
