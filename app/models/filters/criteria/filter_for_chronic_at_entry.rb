class Filters::Criteria::FilterForChronicAtEntry < Filters::Criteria::Base
  LEVEL = :client

  def applies? = config.chronic_at_entry && input.chronic_status

  def apply(scope)
    scope.joins(enrollment: :disabilities).
      merge(
        GrdaWarehouse::Hud::Disability.where(
          InformationDate: input.range,
          DisabilityType: input.disabilities,
          DisabilityResponse: GrdaWarehouse::Hud::Disability.positive_responses,
        ),
      )
  end
end
