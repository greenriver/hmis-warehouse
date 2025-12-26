# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::EnrollmentFilters
  MedicalInsuranceFilter = Struct.new(:id, :label, :types, keyword_init: true) do
    # Filter households based on medical insurance aggregated at the household level.
    def apply(scope)
      scope.where.overlaps(household_medical_insurance_types: types.map(&:to_s))
    end

    def self.all
      filters = [
        new(
          id: :medicaid,
          label: 'MEDICAID Health Program or local program equivalent',
          types: [:Medicaid],
        ),
        new(
          id: :medicare,
          label: 'MEDICARE Health Insurance or local program equivalent',
          types: [:Medicare],
        ),
        new(
          id: :va_medical_services,
          label: 'Veterans Affairs Medical Services',
          types: [:VAMedicalServices],
        ),
        new(
          id: :hiv_aids_assistance,
          label: 'AIDS Drug Assistance Program',
          types: [:HIVAIDSAssistance],
        ),
        new(
          id: :schip,
          label: "State Children's Health Insurance Program (SCHIP) or local program equivalent",
          types: [:SCHIP],
        ),
        new(
          id: :ryan_white_med_dent,
          label: 'Ryan White-funded Medical or Dental Assistance',
          types: [:RyanWhiteMedDent],
        ),
      ]

      total_filter = IncludeFilter.new(
        id: :any_insurance,
        label: 'How many households accessed or maintained access to the following sources of medical insurance in the past year?',
        filters: filters,
      )
      [total_filter] + filters
    end

    def self.any_insurance
      all.detect { |f| f.id == :any_insurance }
    end
  end
end
