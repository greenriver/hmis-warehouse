class Filters::Criteria::FilterForSubPopulation < Filters::Criteria::Base
  LEVEL = :client

  def applies? = input.sub_population.present?

  def apply(scope)
    raise unless sub_population.in?(AvailableSubPopulations.available_sub_populations)

    scope.public_send(input.sub_population)
  end
end
