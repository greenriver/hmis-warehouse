# frozen_string_literal: true

class Filters::Criteria::FilterForDestination < Filters::Criteria::Base
  def applies? = input.destination_ids.present?

  def apply(scope)
    scope = super(scope)
    scope.where(destination: input.destination_ids)
  end
end
