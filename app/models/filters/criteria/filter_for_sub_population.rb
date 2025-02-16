class Filters::Criteria::FilterForSubPopulation < Filters::Criteria::Base
  def applies? = input.sub_population.present?

  def apply(scope)
    raise "input #{input.sub_population} not allowed" unless input.sub_population.in?(AvailableSubPopulations.available_sub_populations.values)

    scope.public_send(input.sub_population)
  end
end
