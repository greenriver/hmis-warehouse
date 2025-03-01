# frozen_string_literal: true

class Filters::Criteria::FilterForDisabilities < Filters::Criteria::Base
  def applies? = input.disabilities.present?

  def apply(scope)
    scope = super(scope)
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
