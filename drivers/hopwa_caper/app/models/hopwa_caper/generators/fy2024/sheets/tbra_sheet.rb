###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class TbraSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q2: TBRA'.freeze
    QUESTION_NUMBERS = ['Q2'].freeze
    SHEET_TITLE = 'Complete this section for all Households served with HOPWA Tenant-Based Rental Assistance (TBRA) by your organization in the reporting year.'.freeze
    CONTENTS = [
      { method: :households_served_sheet, label: 'TBRA Households Served and Expenditures' },
      { method: :other_rental_assistance_sheet, label: 'Other (Non-TBRA) Rental Assistance Households Served and Expenditures' },
      { method: :income_levels_sheet, label: 'Income Levels for Households Served by this Activity' },
      { method: :income_sources_sheet, label: 'Sources of Income for Households Served by this Activity' },
      { method: :medical_insurance, label: 'Medical Insurance for Households Served by this Activity' },
      { method: :health_outcomes_sheet, label: 'Health Outcomes for Households Served by this Activity' },
      { method: :longevity_sheet, label: 'Longevity for Households Served by this Activity' },
      { method: :housing_outcomes_sheet, label: 'Housing Outcomes for Households Served by this Activity' },
    ].freeze

    protected

    def relevant_enrollments
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa
      overlapping_enrollments(program_filter.apply(@report.hopwa_caper_enrollments))
    end

    def households_served_sheet(sheet)
      add_household_enrollments_row(sheet, label: 'How many households were served with HOPWA TBRA assistance?', enrollments: relevant_enrollments)
      sheet.append_row(label: 'What were the total HOPWA funds expended for TBRA rental assistance?')
    end

    def other_rental_assistance_sheet(sheet)
      # we can't calculate these
      [
        'How many total households were served with Other (non-TBRA) Rental Assistance?',
        'What were the total HOPWA funds expended for Other (non-TBRA) Rental Assistance, as approved in the grant agreement?',
        'Describe the Other (non-TBRA) Rental Assistance provided. (150 characters).',
        'TBRA Household Total (TBRA + Other)',
      ].each do |label|
        sheet.append_row(label: label)
      end
    end

    def health_outcomes_sheet(sheet)
      sheet.append_row(label: 'How many HOPWA-eligible individuals served with TBRA this year have ever been prescribed Anti-Retroviral Therapy?') do |row|
        cell_scope = relevant_enrollments.where(hopwa_eligible: true, ever_prescribed_anti_retroviral_therapy: true)
        row.append_cell_members(members: cell_scope.latest_by_personal_id.as_report_members)
      end

      sheet.append_row(label: 'How many HOPWA-eligible persons served with TBRA have shown an improved viral load or achieved viral suppression?') do |row|
        cell_scope = relevant_enrollments.where(hopwa_eligible: true, viral_load_suppression: true)
        row.append_cell_members(members: cell_scope.latest_by_personal_id.as_report_members)
      end
    end

    def longevity_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::TbraLongevityFilter.for_report(@report)
      filters.each do |filter|
        add_household_enrollments_row(
          sheet,
          label: filter.label,
          enrollments: filter.apply(relevant_enrollments),
        )
      end
    end
  end
end
