# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  IncomeBenefitSourceFilter = Struct.new(:id, :label, :types, keyword_init: true) do
    # Filter households based on income sources aggregated at the household level.
    # - For specific income types: households where aggregated values overlap
    # - For no income (types: []): households where aggregated values are empty
    def apply(scope)
      return scope.where.overlaps(household_income_benefit_source_types: types.map(&:to_s)) if types.present?

      scope.where(household_income_benefit_source_types: [])
    end

    def self.all
      filters = [
        new(
          id: :earned,
          label: 'Earned Income from Employment',
          types: [:Earned],
        ),
        new(
          id: :retirement,
          label: 'Retirement',
          types: [:SocSecRetirement],
        ),
        new(
          id: :ssi,
          label: 'SSI',
          types: [:SSI],
        ),
        new(
          id: :ssdi,
          label: 'SSDI',
          types: [:SSDI],
        ),
        new(
          id: :welfare,
          label: 'Other Welfare Assistance (Supplemental Nutrition Assistance Program, WIC, TANF, etc.)',
          types: [:SNAP, :WIC, :TANF],
        ),
        new(
          id: :private_disability,
          label: 'Private Disability Insurance',
          types: [:PrivateDisability],
        ),
        new(
          id: :va_disability,
          label: "Veteran's Disability Payment (service or non-service connected payment)",
          types: [:VADisabilityService, :VADisabilityNonService],
        ),
        new(
          id: :contributions,
          label: 'Regular contributions or gifts from organizations or persons not residing in the residence',
          types: [:ChildSupport, :Alimony, :Pension],
        ),
        new(
          id: :workers_comp,
          label: "Worker's Compensation",
          types: [:WorkersComp],
        ),
        new(
          id: :ga,
          label: 'General Assistance (GA), or local program',
          types: [:GA],
        ),
        new(
          id: :unemployment,
          label: 'Unemployment Insurance',
          types: [:Unemployment],
        ),
        new(
          id: :other,
          label: 'Other Sources of Income',
          types: [:OtherIncomeSource],
        ),
        new(
          id: :no_income,
          label: 'How many households maintained no sources of income?',
          types: [],
        ),
      ]
      total_filter = IncludeFilter.new(
        id: :any_income,
        label: 'How many households accessed or maintained access to the following sources of income in the past year?',
        filters: filters,
      )
      [total_filter] + filters
    end

    def self.any_income
      all.detect { |f| f.id == :any_income }
    end

    def self.no_income
      all.detect { |f| f.id == :no_income }
    end

    def self.earned_income
      all.detect { |f| f.id == :earned }
    end
  end
end
