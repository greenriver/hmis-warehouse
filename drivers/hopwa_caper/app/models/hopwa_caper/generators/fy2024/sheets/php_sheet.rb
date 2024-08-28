###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class PhpSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q4: PHP'.freeze
    QUESTION_NUMBERS = ['Q4'].freeze
    CONTENTS = [
      { method: :households_served_sheet, label: 'Households Served by this Activity' },
      { method: :expenditures_sheet, label: 'PHP Expenditures for Households Served by this Activity' },
      { method: :income_sources_sheet, label: 'Sources of Income for Households Served by this Activity' },
      { method: :medical_insurance, label: 'Medical Insurance for Households Served by this Activity' },
      { method: :housing_outcomes_sheet, label: 'Housing Outcomes for Households Served by this Activity' },
    ].freeze

    protected

    def relevant_enrollments_filter
      HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.php_hopwa
    end

    def relevant_services_filter
      HopwaCaper::Generators::Fy2024::ServiceFilters::RecordTypeFilter.hopwa_financial_assistance
    end

    def households_served_sheet(sheet)
      add_household_enrollments_row(
        sheet,
        label: 'How many households were served with PHP assistance?',
        enrollments: relevant_enrollments,
      )
    end

    def expenditures_sheet(sheet)
      add_sevices_fa_amount_row(
        sheet,
        label: 'What were the HOPWA funds expended for PHP?',
        services: relevant_services,
      )
    end
  end
end
