class Filters::Criteria::FilterForDvCurrentlyFleeing < Filters::Criteria::Base
  def applies? = input.currently_fleeing.present?

  def apply(scope)
    scope.joins(enrollment: :health_and_dvs).
      merge(
        GrdaWarehouse::Hud::HealthAndDv.where(
          InformationDate: input.range,
          CurrentlyFleeing: input.currently_fleeing,
        ),
      )
  end
end
