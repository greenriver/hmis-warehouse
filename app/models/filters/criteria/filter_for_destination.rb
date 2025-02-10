class Filters::Criteria::FilterForDestination < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.destination_ids.present?

  def apply(scope)
    scope.where(destination: input.destination_ids)
  end
end
