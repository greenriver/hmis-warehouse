###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  ProjectFunderFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      cond = SqlHelper.non_empty_array_subset_condition(field: 'project_funders', type: 'integer', set: funders)
      scope.where(cond)
    end

    def funders
      types.map do |type|
        HudUtility2024.funding_sources.invert.fetch(type)
      end
    end

    def self.tbra_hopwa
      new(
        label: 'TBRA',
        types: [
          'HUD: HOPWA - Permanent Housing (facility based or TBRA)',
          'HUD: HOPWA - Transitional Housing (facility based or TBRA)',
        ],
      )
    end

    def self.strmu_hopwa
      new(
        label: 'STRMU',
        types: ['HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance'],
      )
    end

    def self.php_hopwa
      new(
        label: 'PHP',
        types: ['HUD: HOPWA - Permanent Housing Placement'],
      )
    end

    def self.tbra_or_php_hopwa
      IncludeFilter.new(filters: [tbra_hopwa, php_hopwa])
    end
  end
end
