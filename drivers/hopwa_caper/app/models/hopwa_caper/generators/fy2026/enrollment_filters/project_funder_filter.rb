# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  ProjectFunderFilter = Struct.new(:label, :types, :range, keyword_init: true) do
    def apply(scope)
      # Find projects with ANY of the specified funders (not subset, since projects can have multiple funding sources).
      # Ensure the enrollment actually overlaps with the funding period.
      # Scope funders to the same report as the enrollment scope to avoid cross-report contamination.
      funder_scope = HopwaCaper::Funder.
        where(report_instance_id: scope.distinct.pluck(:report_instance_id)).
        where(code: codes).
        within_range(range)

      scope.where(project_id: funder_scope.distinct.pluck(:project_id)).within_range(range)
    end

    def codes
      types.map do |type|
        HudHelper.util('2026').funding_sources.invert.fetch(type)
      end
    end

    def self.tbra_hopwa(range: nil)
      new(
        label: 'TBRA',
        range: range,
        types: [
          'HUD: HOPWA - Permanent Housing (facility based or TBRA)',
          'HUD: HOPWA - Transitional Housing (facility based or TBRA)',
        ],
      )
    end

    def self.strmu_hopwa(range: nil)
      new(
        label: 'STRMU',
        range: range,
        types: ['HUD: HOPWA - Short-Term Rent, Mortgage, Utility assistance'],
      )
    end

    def self.php_hopwa(range: nil)
      new(
        label: 'PHP',
        range: range,
        types: ['HUD: HOPWA - Permanent Housing Placement'],
      )
    end

    def self.tbra_or_php_hopwa(range: nil)
      IncludeFilter.new(filters: [tbra_hopwa(range: range), php_hopwa(range: range)])
    end
  end
end
