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

    def relevant_enrollments
      service_scope = HopwaCaper::Service.where(date_provided: @report.start_date...@report.end_date).hopwa_financial_assistance
      @report.hopwa_caper_enrollments.
        php_funder.
        overlapping_range(start_date: @report.start_date, end_date: @report.end_date).
        joins(:services).
        merge(service_scope)
    end

    def relevant_services
      enrolment_scope = HopwaCaper::Enrollment.php_funder.overlapping_range(start_date: @report.start_date, end_date: @report.end_date)
      @report.hopwa_caper_services.hopwa_financial_assistance.
        where(date_provided: @report.start_date...@report.end_date).
        joins(:enrollment).merge(enrolment_scope)
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
