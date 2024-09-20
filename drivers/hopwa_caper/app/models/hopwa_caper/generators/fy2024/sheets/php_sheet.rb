###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class PhpSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q4: PHP'.freeze
    QUESTION_NUMBERS = ['Q4'].freeze
    SHEET_TITLE = 'Complete this section for all Households served with HOPWA Permanent Housing Placement (PHP) assistance by your organization in the reporting year.'.freeze
    CONTENTS = [
      { method: :households_served_sheet, label: 'Households Served by this Activity' },
      { method: :expenditures_sheet, label: 'PHP Expenditures for Households Served by this Activity' },
      { method: :income_sources_sheet, label: 'Sources of Income for Households Served by this Activity' },
      { method: :medical_insurance, label: 'Medical Insurance for Households Served by this Activity' },
      { method: :housing_outcomes_sheet, label: 'Housing Outcomes for Households Served by this Activity' },
    ].freeze

    protected

    def relevant_enrollments
      program_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.php_hopwa
      overlapping_enrollments(program_filter.apply(@report.hopwa_caper_enrollments))
    end

    def expenditures_sheet(sheet)
      sheet.append_row(label: 'What were the HOPWA funds expended for PHP?')
    end

    def households_served_sheet(sheet)
      add_household_enrollments_row(
        sheet,
        label: 'How many households were served with PHP assistance?',
        enrollments: relevant_enrollments,
      )
    end

    def housing_outcomes_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ExitDestinationFilter.php_destinations
      total_filter = HopwaCaper::Generators::Fy2024::EnrollmentFilters::IncludeFilter.new(label: 'Housing Outcomes for Households Served by this Activity', filters: filters)
      add_household_enrollments_row(
        sheet,
        label: 'Housing Outcomes for Households Served by this Activity',
        enrollments: total_filter.apply(relevant_enrollments),
      )

      sheet.append_row(label: 'In the context of PHP, "exited" means the housing situation into which the household was placed using the PHP assistance.')
      filters.each do |filter|
        add_household_enrollments_row(sheet, label: filter.label, enrollments: filter.apply(relevant_enrollments))
      end
    end
  end
end
