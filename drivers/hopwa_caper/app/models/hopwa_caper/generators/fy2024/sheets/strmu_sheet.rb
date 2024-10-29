###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2024::Sheets
  class StrmuSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q3: STRMU'.freeze
    QUESTION_NUMBERS = ['Q3'].freeze
    SHEET_TITLE = 'Complete this section for all Households served with HOPWA Short-Term Rent, Mortgage, and Utilities Assistance (STRMU) by your organization in the reporting year.'.freeze
    CONTENTS = [
      { method: :households_served_sheet, label: 'Households Served by this Activity - STRMU Breakdown' },
      { method: :expenditures_sheet, label: 'STRMU Expenditures' },
      { method: :income_levels_sheet, label: nil },
      { method: :income_sources_sheet, label: 'Sources of Income for Households Served by this Activity' },
      { method: :medical_insurance, label: 'Medical Insurance for Households Served by this Activity' },
      { method: :longevity_sheet, label: nil },
      { method: :housing_outcomes_sheet, label: 'Housing Outcomes for Households Served by this Activity' },
    ].freeze

    protected

    def program_filter
      HopwaCaper::Generators::Fy2024::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa
    end

    def relevant_enrollments
      overlapping_enrollments(program_filter.apply(@report.hopwa_caper_enrollments))
    end

    def relevant_services
      service_filter = HopwaCaper::Generators::Fy2024::ServiceFilters::RecordTypeFilter.hopwa_financial_assistance
      service_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date...@report.end_date).
        joins(:enrollment).merge(relevant_enrollments)
    end

    def service_type_filters
      HopwaCaper::Generators::Fy2024::ServiceFilters::StrmuServiceTypeFilter
    end

    def households_served_sheet(sheet)
      seen_household_ids = []
      service_type_filters.all.each do |filter|
        filtered_scope = filter.having_exclusive_type(relevant_services.group(:report_household_id))
        cell_scope = HopwaCaper::Enrollment.where(
          report_household_id: filtered_scope.select(:report_household_id),
        )
        seen_household_ids += cell_scope.to_a.map(&:report_household_id)
        add_household_enrollments_row(
          sheet,
          label: "How many households were served with STRMU #{filter.label} only?",
          enrollments: cell_scope,
        )
      end

      add_household_enrollments_row(
        sheet,
        label: 'How many households received more than one type of STRMU assistance?',
        enrollments: relevant_enrollments.where.not(report_household_id: seen_household_ids.uniq.sort),
      )
      add_household_enrollments_row(
        sheet,
        label: 'STRMU Households Total',
        enrollments: relevant_enrollments,
      )
    end

    def expenditures_sheet(sheet)
      sheet.append_row(label: 'What were the HOPWA funds expended for the following budget line items?')
      service_type_filters.all.each do |filter|
        sheet.append_row(label: "STRMU #{filter.label}")
      end
      sheet.append_row(label: 'Total STRMU Expenditures')
    end

    def longevity_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::StrmuLongevityFilter.for_report(@report)
      filters.each do |filter|
        add_household_enrollments_row(
          sheet,
          label: filter.label,
          enrollments: filter.apply(relevant_enrollments),
        )
      end
    end

    def housing_outcomes_sheet(sheet)
      super
      sheet.append_row(label: 'How many households are likely to need additional Short-Term Rent, Mortgage and Utilities assistance to maintain the current housing arrangements?')
    end
  end
end
