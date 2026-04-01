# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  IncomeBenefitSourceFilter = Struct.new(:id, :label, :types, keyword_init: true) do
    # Filter households based on income sources aggregated at the household level.
    # Following HUD reporting glossary strategy:
    # 1. Income is assessed for Adults and Heads of Household.
    # 2. If ANY member of this universe has income, the household is considered to have that source.
    # 3. "No Income" is only counted if the household has no income sources AND at least one member
    #    has an explicit "No Income" assessment.
    def apply(scope)
      if id == :no_income
        # Strict equivalence ensures the household has an affirmative "No"
        # and no other income sources.
        return scope.where(household_income_benefit_source_types: types.map(&:to_s))
      end

      scope.where.overlaps(household_income_benefit_source_types: types.map(&:to_s))
    end

    def self.all
      specific_filters = [
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
      ]

      no_income_filter = new(
        id: :no_income,
        label: 'How many households maintained no sources of income?',
        types: [:NoIncomeSource],
      )

      all_income_types = specific_filters.flat_map(&:types) + [:IncomeFromAnySource, :NoIncomeSource]

      total_filter = new(
        id: :any_income,
        label: 'How many households accessed or maintained access to the following sources of income in the past year?',
        types: all_income_types,
      )

      [total_filter] + specific_filters + [no_income_filter]
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
