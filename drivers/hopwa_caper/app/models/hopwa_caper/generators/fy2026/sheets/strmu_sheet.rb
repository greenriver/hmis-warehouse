# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class StrmuSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q3: STRMU'
    QUESTION_NUMBERS = ['Q3'].freeze
    SHEET_TITLE = 'Complete this section for all Households served with HOPWA Short-Term Rent, Mortgage, and Utilities Assistance (STRMU) by your organization in the reporting year.'
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
      HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa(range: @report.report_range)
    end

    def base_enrollments
      program_filter.apply(@report.hopwa_caper_enrollments)
    end

    def relevant_enrollments
      # Resolve HOH client IDs that received STRMU services
      hoh_client_ids = @report.hopwa_caper_enrollments.
        head_of_household.
        where(report_household_id: relevant_services.select(:report_household_id)).
        select(:destination_client_id)

      @report.hopwa_caper_enrollments.
        head_of_household.
        where(destination_client_id: hoh_client_ids).
        latest_by_distinct_client_id
    end

    def relevant_services
      service_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_financial_assistance
      service_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date..@report.end_date).
        joins(:enrollment).merge(base_enrollments)
    end

    def service_type_filters
      HopwaCaper::Generators::Fy2026::ServiceFilters::StrmuServiceTypeFilter
    end

    def households_served_sheet(sheet)
      # Find HOH client IDs for services of each type.
      # Note: services_with_hoh joins services to the HOH via report_household_id,
      # ensuring that services provided to ANY household member are attributed to the household's HOH.
      service_type_filters.all.each do |filter|
        # Households with ONLY this type of STRMU service, aggregated by HOH client ID
        exclusive_hoh_client_ids = filter.
          having_exclusive_type(services_with_hoh(relevant_services).group('hoh.destination_client_id')).
          select('hoh.destination_client_id')

        cell_scope = @report.hopwa_caper_enrollments.
          head_of_household.
          where(destination_client_id: exclusive_hoh_client_ids).
          latest_by_distinct_client_id

        add_household_enrollments_row(
          sheet,
          label: "How many households were served with STRMU #{filter.label} only?",
          enrollments: cell_scope,
        )
      end

      # row 7
      # Multi-type: households with more than one distinct service type, aggregated by HOH client ID
      service_type_filter_cases = service_type_filters.all.
        map.with_index { |f, idx| "WHEN type_provided IN (#{f.codes.map(&:to_i).join(', ')}) THEN #{idx}" }
      multi_type_hoh_client_ids = services_with_hoh(relevant_services).
        group('hoh.destination_client_id').
        having("COUNT(DISTINCT CASE #{service_type_filter_cases.join(' ')} END) > 1").
        select('hoh.destination_client_id')

      add_household_enrollments_row(
        sheet,
        label: 'How many households received more than one type of STRMU assistance?',
        enrollments: @report.hopwa_caper_enrollments.
          head_of_household.
          where(destination_client_id: multi_type_hoh_client_ids).
          latest_by_distinct_client_id,
      )

      add_household_enrollments_row(
        sheet,
        label: 'STRMU Households Total',
        enrollments: relevant_enrollments,
      )
    end

    def expenditures_sheet(sheet)
      sheet.append_row(label: 'What were the HOPWA funds expended for the following budget line items?')
      total_expenditures = 0
      service_type_filters.all.each do |filter|
        sheet.append_row(label: "STRMU #{filter.label}") do |row|
          services = filter.apply(relevant_services)
          value = services.sum(&:fa_amount)
          total_expenditures += value
          row.append_cell_members(value: value, members: services.as_report_members)
        end
      end

      sheet.append_row(label: 'Total STRMU Expenditures') do |row|
        row.append_cell_value(value: total_expenditures)
      end
    end

    def longevity_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::StrmuLongevityFilter.for_report(@report)
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
