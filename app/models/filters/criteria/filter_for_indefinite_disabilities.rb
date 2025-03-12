# frozen_string_literal: true

class Filters::Criteria::FilterForIndefiniteDisabilities < Filters::Criteria::Base
  def applies? = input.indefinite_disabilities.present?

  def apply(scope)
    scope = super(scope)
    scope.joins(enrollment: :disabilities).
      merge(
        GrdaWarehouse::Hud::Disability.where(
          InformationDate: input.range,
          IndefiniteAndImpairs: input.indefinite_disabilities,
        ),
      )
  end
end
