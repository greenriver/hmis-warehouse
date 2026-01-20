# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  ProjectFunderFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      # Find projects with ANY of the specified funders (not subset, since projects can have multiple funding sources)
      scope.where.overlaps(project_funders: funders)
    end

    def funders
      @funders ||= types.map do |type|
        HudHelper.util('2026').funding_sources.invert.fetch(type)
      end.freeze
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

    def self.all
      @all ||= [tbra_hopwa, strmu_hopwa, php_hopwa].freeze
    end

    def self.find_by_funder_code(code)
      # Find the first filter that matches the combination
      all.find { |f| f.funders.include?(code) }
    end
  end
end
