###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::ServiceFilters
  StrmuServiceTypeFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.where(type_provided: codes)
    end

    def having_exclusive_type(grouped)
      cond = SqlHelper.non_empty_array_subset_condition(field: 'ARRAY_AGG(DISTINCT type_provided)', type: 'integer', set: codes)
      grouped.having(cond)
    end

    def codes
      service_types = HudUtility2024.hopwa_financial_assistance_options.invert
      types.map { |type| service_types.fetch(type) }
    end

    def self.all
      [
        new(
          label: 'mortgage assistance',
          types: ['Mortgage assistance'],
        ),
        new(
          label: 'rental assistance',
          types: ['Rental assistance', 'Security deposits'],
        ),
        new(
          label: 'utilities assistance',
          types: ['Utility deposits', 'Utility payments'],
        ),
      ]
    end
  end
end
