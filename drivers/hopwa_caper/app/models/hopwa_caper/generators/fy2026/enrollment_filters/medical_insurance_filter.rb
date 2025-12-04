# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  MedicalInsuranceFilter = Struct.new(:label, :types, keyword_init: true) do
    # Filter households based on medical insurance across all household members.
    # Includes households where ANY member has the specified medical insurance types.
    def apply(scope)
      # Get unique household IDs from the current scope to constrain household lookups
      household_ids = scope.select(:report_household_id).distinct

      # Look at ALL members of households in scope, not just the scoped members
      cond = HopwaCaper::Enrollment.
        where(report_household_id: household_ids).
        where(SqlHelper.array_overlap_condition(field: 'medical_insurance_types', set: types, type: 'varchar')).
        select(:report_household_id).
        distinct
      scope.where(report_household_id: cond)
    end

    def self.all
      filters = [
        new(
          label: 'MEDICAID Health Program or local program equivalent',
          types: [:Medicaid],
        ),
        new(
          label: 'MEDICARE Health Insurance or local program equivalent',
          types: [:Medicare],
        ),
        new(
          label: 'Veterans Affairs Medical Services',
          types: [:VAMedicalServices],
        ),
        new(
          label: 'AIDS Drug Assistance Program',
          types: [:HIVAIDSAssistance],
        ),
        new(
          label: "State Children's Health Insurance Program (SCHIP) or local program equivalent",
          types: [:SCHIP],
        ),
        new(
          label: 'Ryan White-funded Medical or Dental Assistance',
          types: [:RyanWhiteMedDent],
        ),
      ]

      total_filter = IncludeFilter.new(
        label: 'How many households accessed or maintained access to the following sources of medical insurance in the past year?',
        filters: filters,
      )
      [total_filter] + filters
    end
  end
end
