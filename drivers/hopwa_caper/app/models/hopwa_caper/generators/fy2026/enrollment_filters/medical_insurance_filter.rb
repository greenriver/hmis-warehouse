# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  MedicalInsuranceFilter = Struct.new(:label, :types, keyword_init: true) do
    include HouseholdScopedFilter

    # Filter households based on medical insurance across all household members.
    # Includes households where ANY member has the specified medical insurance types.
    def apply(scope)
      households_with_any_member_having(scope, field: 'medical_insurance_types', values: types, type: 'varchar')
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
