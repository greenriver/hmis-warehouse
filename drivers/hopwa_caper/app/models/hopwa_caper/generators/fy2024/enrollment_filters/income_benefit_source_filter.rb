###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  IncomeBenefitSourceFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      cond = if types.present?
        SqlHelper.non_empty_array_subset_condition(field: 'income_benefit_source_types', type: :varchar, set: types)
      else
        # no benefits
        "income_benefit_source_types = '{}'::varchar[]"
      end
      scope.where(cond)
    end

    def self.all
      [
        new(
          label: 'Earned Income from Employment',
          types: [:Earned],
        ),
        new(
          label: 'Retirement',
          types: [:SocSecRetirement],
        ),
        new(
          label: 'SSI',
          types: [:SSI],
        ),
        new(
          label: 'SSDI',
          types: [:SSDI],
        ),
        new(
          label: 'Other Welfare Assistance (Supplemental Nutrition Assistance Program, WIC, TANF, etc.)',
          types: [:SNAP, :WIC, :TANF],
        ),
        new(
          label: 'Private Disability Insurance',
          types: [:PrivateDisability],
        ),
        new(
          label: "Veteran's Disability Payment (service or non-service connected payment)",
          types: [:VADisabilityService, :VADisabilityNonService],
        ),
        new(
          label: 'Regular contributions or gifts from organizations or persons not residing in the residence',
          types: [:ChildSupport, :Alimony, :Pension],
        ),
        new(
          label: "Worker's Compensation",
          types: [:WorkersComp],
        ),
        new(
          label: 'General Assistance (GA), or local program',
          types: [:GA],
        ),
        new(
          label: 'Unemployment Insurance',
          types: [:Unemployment],
        ),
        new(
          label: 'Other Sources of Income',
          types: [:OtherIncomeSource],
        ),
        new(
          label: 'How many households maintained no sources of income?',
          types: [],
        ),
      ]
    end
  end
end
