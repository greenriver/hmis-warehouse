###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  PriorLivingSituationFilter = Struct.new(:label, :types, :rental_subsidy_types, keyword_init: true) do
    def apply(scope)
      scope = scope.where(rental_subsidy_type: rental_subsidy_type_codes) if rental_subsidy_types
      scope.where(prior_living_situation: codes)
    end

    def rental_subsidy_type_codes
      lookup = HudUtility2024.rental_subsidy_types.invert
      rental_subsidy_types.map do |type|
        lookup.fetch(type)
      end
    end

    def codes
      lookup = HudUtility2024.situations_for(:prior).invert
      types.map do |type|
        lookup.fetch(type)
      end
    end

    def self.all
      filters = [
        new(
          label: 'A place not meant for human habitation?',
          types: ['Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)'],
        ),
        new(
          label: 'An emergency shelter?',
          types: ['Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or Host Home shelter'],
        ),
        new(
          label: 'A transitional housing facility for formerly homeless persons?',
          types: ['Transitional housing for homeless persons (including homeless youth)'],
        ),
        new(
          label: 'A permanent housing situation for formerly homeless persons?',
          types: [
            'Rental by client, with ongoing housing subsidy',
          ],
          rental_subsidy_types: [
            "VASH housing subsidy",
            "Permanent Supportive Housing",
            "Other permanent housing dedicated for formerly homeless persons",
          ]
        ),
        new(
          label: 'A psychiatric hospital or other psychiatric facility?',
          types: ['Psychiatric hospital or other psychiatric facility'],
        ),
        new(
          label: 'A substance abuse facility?',
          types: ['Substance abuse treatment facility or detox center'],
        ),
        new(
          label: 'A non-psychiatric hospital?',
          types: ['Hospital or other residential non-psychiatric medical facility'],
        ),
        new(
          label: 'A foster care home?',
          types: ['Foster care home or foster care group home'],
        ),
        new(
          label: 'Jail, prison, or a juvenile detention facility?',
          types: ['Jail, prison or juvenile detention facility'],
        ),
        new(
          label: 'A rented room, apartment or house?',
          types: [
            'Rental by client, no ongoing housing subsidy',
            'Rental by client, with ongoing housing subsidy',
          ],
        ),
        new(
          label: 'A house the individual owned?',
          types: ['Owned by client, no ongoing housing subsidy', 'Owned by client, with ongoing housing subsidy'],
        ),
        new(
          label: "Staying at someone else's house?",
          types: ['Staying or living in a family member’s room, apartment, or house', "Staying or living in a friend's room, apartment or house"],
        ),
        new(
          label: 'A hotel or motel paid for by the individual?',
          types: ['Hotel or motel paid for without emergency shelter voucher'],
        ),
      ]

      other_filter = ExcludeFilter.new(
        label: 'Any other prior living situation?',
        filters: filters,
      )
      [other_filter] + filters
    end
  end
end
