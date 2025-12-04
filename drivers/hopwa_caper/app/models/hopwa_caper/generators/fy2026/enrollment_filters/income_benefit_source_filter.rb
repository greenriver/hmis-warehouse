# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  IncomeBenefitSourceFilter = Struct.new(:label, :types, keyword_init: true) do
    # Filter households based on income sources across all household members.
    # - For specific income types: includes households where ANY member has those income sources
    # - For no income (types: []): includes households where ALL members have no income sources
    def apply(scope)
      # Get unique household IDs from the current scope to constrain household lookups
      household_ids = scope.select(:report_household_id).distinct

      if types.present?
        # Household has income if ANY member has the specified income types
        # Look at ALL members of households in scope, not just the scoped members
        cond = HopwaCaper::Enrollment.
          where(report_household_id: household_ids).
          where(SqlHelper.array_overlap_condition(field: 'income_benefit_source_types', set: types, type: :varchar)).
          select(:report_household_id).
          distinct
      else
        # Household has no income only if ALL members have empty income_benefit_source_types
        cond = HopwaCaper::Enrollment.
          where(report_household_id: household_ids).
          group(:report_household_id).
          having("BOOL_AND(income_benefit_source_types = '{}'::varchar[])").
          select(:report_household_id)
      end
      scope.where(report_household_id: cond)
    end

    def self.all
      filters = [
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
      total_filter = IncludeFilter.new(
        label: 'How many households accessed or maintained access to the following sources of income in the past year?',
        filters: filters,
      )
      [total_filter] + filters
    end
  end
end
