###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Filters::Criteria::FilterForSubPopulation < Filters::Criteria::Base
  def applies? = input.sub_population.present?

  def apply(scope)
    scope = super(scope)
    raise "input #{input.sub_population} not allowed" unless input.sub_population.in?(AvailableSubPopulations.available_sub_populations.values)

    scope.public_send(input.sub_population)
  end
end
