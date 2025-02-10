class Filters::Criteria::FilterForCaHomeless < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.coordinated_assessment_living_situation_homeless

  # This needs to work correctly with project type filters, where it adds the
  # potentially additional type of CA, but only if LivingSituation (3.917.1) is
  # of a homeless type (6, 1, 18)
  def apply(scope)
    p_types = config.project_types.presence || input.project_type_ids
    scope.joins(:enrollment).where(
      arel.she_t[:project_type].in(HudUtility2024.performance_reporting[:ce]).
      and(arel.e_t[:LivingSituation].in(HudUtility2024.homeless_situations(as: :prior))).
      or(arel.she_t[:project_type].in(p_types)),
    )
  end
end
