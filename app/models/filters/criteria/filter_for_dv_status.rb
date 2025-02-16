class Filters::Criteria::FilterForDvStatus < Filters::Criteria::Base
  def applies? = input.dv_status.present?

  def apply(scope)
    scope.joins(enrollment: :health_and_dvs).
      merge(
        GrdaWarehouse::Hud::HealthAndDv.where(
          InformationDate: input.range,
          DomesticViolenceSurvivor: input.dv_status,
        ),
      )
  end
end
