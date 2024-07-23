###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters::DemographicFilters
  def self.race_ethnicity_combination_filters
    {}.tap do |h|
      HudUtility2024.race_ethnicity_combinations.keys.each do |combination|
        h[combination] = {
          name: HudUtility2024.race_ethnicity_combinations[combination],
          extra_filters: {
            race_ethnicity_combinations: [combination],
          },
          demographic_filters: [:filter_for_race_ethnicity_combinations],
        }
      end
    end
  end

  def self.subpopulation_filters
    {
      fleeing_dv: {
        name: 'Currently Fleeing DV',
        extra_filters: {
          currently_fleeing: [1],
        },
        demographic_filters: [:filter_for_dv_currently_fleeing],
      },
      veteran: {
        name: 'Veterans',
        extra_filters: {
          veteran_statuses: [1],
        },
        demographic_filters: [:filter_for_veteran_status],
      },
      has_disability: {
        name: 'With Indefinite and Impairing Disability',
        extra_filters: {
          indefinite_disabilities: [1],
        },
        demographic_filters: [:filter_for_indefinite_disabilities],
      },
    }
  end
end
