###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::EnrollmentFilters
  MedicalInsuranceFilter = Struct.new(:label, :types, keyword_init: true) do
    def apply(scope)
      scope.where(
        SqlHelper.non_empty_array_subset_condition(field: 'medical_insurance_types', type: 'varchar', set: types),
      )
    end

    def self.all
      [
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
    end
  end
end
