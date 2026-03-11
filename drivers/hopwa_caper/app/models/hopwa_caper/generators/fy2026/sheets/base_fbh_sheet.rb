# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class BaseFbhSheet < Base
    def relevant_services
      service_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_financial_assistance
      service_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date..@report.end_date).
        where(enrollment_id: relevant_enrollments.pluck(:enrollment_id))
    end

    def relevant_enrollments
      program_filter.apply(@report.hopwa_caper_enrollments)
    end

    # projects are not snapshotted, so we query them live
    def project_scope
      project_ids = @report.hopwa_caper_funders.
        within_range(@report.report_range).
        where(code: program_filter.codes).
        select(:project_id)

      GrdaWarehouse::Hud::Project.
        where(arel.p_t[:HousingType].in([1, 2])).
        where(id: project_ids)
    end

    def facilities
      @facilities ||= project_scope.order(:project_name, :id).map.with_index do |project, idx|
        HopwaCaper::Facility.new(
          project: project,
          report: @report,
          position: idx + 1,
        )
      end
    end

    def add_header(sheet)
      letter = 'A'
      sheet.add_header(col: letter, label: self.class::SHEET_TITLE)
      facilities.each do |_fac|
        letter = letter.next
        sheet.add_header(col: letter, label: '')
      end
      facility_row(sheet, label: 'Question') do |fac, row|
        row.append_cell_value(value: "Facility #{fac.position}")
      end
    end

    def facility_information(sheet)
      sheet.append_row(label: 'Facility Information')

      facility_row(sheet, label: 'What is the name of the housing facility?') do |fac, row|
        row.append_cell_value(value: fac.name)
      end

      facility_row(sheet, label: 'Is the facility a medically assisted living facility? Yes or No.') do |fac, row|
        value = yes_no(fac.medically_assisted_living_facility?)
        row.append_cell_value(value: value)
      end

      facility_row(sheet, label: 'Was the housing facility placed into service during this program year? Yes or No.') do |fac, row|
        value = yes_no(fac.placed_in_service_during_program_year?)
        row.append_cell_value(value: value)
      end

      facility_row(sheet, label: 'For housing facilities placed into service during this program year, how many units were placed into service? [Do not complete if facility placed in service in prior years.]') do |fac, row|
        value = fac.units_placed_into_service if fac.placed_in_service_during_program_year?
        row.append_cell_value(value: value)
      end
    end

    def facility_leasing_expenditures(sheet, fbh_activity_label:)
      sheet.append_row(label: 'Leasing -- Households and Expenditures Served by this Activity Expenditures total should include overhead (staff costs, fringe, etc.).')

      # 2: 'Security deposits'
      # 3: 'Utility deposits'
      leasing_services = relevant_services.where(type_provided: [2, 3])
      facility_row(sheet, label: "How many households received #{fbh_activity_label} Facility-Based Housing Leasing support for each facility?") do |fac, row|
        services = leasing_services.
          joins(:enrollment).
          where(enrollment: { project_id: fac.id }).
          select(:report_household_id).
          distinct

        members = heads_of_household_for(services)
        row.append_cell_members(members: members)
      end

      empty_row(sheet, label: "What were the HOPWA funds expended for #{fbh_activity_label} Facility-Based Housing Leasing Costs for each facility?")
    end

    def facility_operating_expenditures(sheet, fbh_activity_label:)
      sheet.append_row(label: 'Operating -- Households and Expenditures Served by this Activity Expenditures total should include overhead (staff costs, fringe, etc.).')
      empty_row(sheet, label: "How many households received #{fbh_activity_label} Facility-Based Housing Operating support for each facility?")
      empty_row(sheet, label: "What were the HOPWA funds expended for #{fbh_activity_label} Facility-Based Housing Operating Costs for each facility?")
    end

    def income_levels(sheet, spreadsheet_row:, data_check_label:)
      start_index = spreadsheet_row - 2
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitLevelFilter.all

      # Data Check label row
      sheet.set_row(start_index + 1, label: data_check_label)

      # Detail rows (below the summary/label rows)
      # drop(1) because IncomeBenefitLevelFilter.all returns a total filter as first element
      facility_counts = add_filtered_enrollment_facilities(sheet, filters: filters.drop(1), start_index: start_index + 2)

      # Summary row (at the spreadsheet_row coordinate)
      facility_row(sheet, label: 'Income Levels for Households Served by this Activity', index: start_index) do |fac, row|
        row.append_cell_value(value: facility_counts[fac.id])
      end
    end

    def income_sources(sheet, label:)
      sheet.append_row(label: label)
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitSourceFilter.all
      add_filtered_enrollment_facilities(sheet, filters: filters)
    end

    def medical_insurance(sheet, label:)
      sheet.append_row(label: label)
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::MedicalInsuranceFilter.all
      add_filtered_enrollment_facilities(sheet, filters: filters)
    end

    def longevity_for_households(sheet, spreadsheet_row:, data_check_label:, activity_label:)
      all_time = @report.hopwa_caper_enrollments.where(project_id: relevant_enrollments.select(:project_id))
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::EnrollmentLongevityFilter.all(
        activity_label: activity_label,
        end_date: @report.end_date,
        reference_scope: all_time,
        funder_codes: program_filter.codes,
      )

      # spreadsheet_row (e.g., 51) maps to index 49
      start_index = spreadsheet_row - 2
      facility_counts = Hash.new(0)

      # Data Check label row
      sheet.set_row(start_index + 1, label: data_check_label)

      # Detail rows start after the data check label
      filters.drop(1).each.with_index(start_index + 2) do |filter, idx|
        facility_row(sheet, label: filter.label, index: idx) do |fac, row|
          filtered = filter.apply(relevant_enrollments.where(hopwa_eligible: true)).where(project_id: fac.id)
          members = heads_of_household_for(filtered)
          row.append_cell_members(members: members)
          facility_counts[fac.id] += members.size
        end
      end

      # The Data Check summary row (at the spreadsheet_row coordinate)
      facility_row(sheet, label: 'Longevity for Households Served by this Activity', index: start_index) do |fac, row|
        row.append_cell_value(value: facility_counts[fac.id])
      end
    end

    def housing_outcomes(sheet, spreadsheet_row:, data_check_label:)
      start_index = spreadsheet_row - 2
      facility_counts = Hash.new(0)
      # update_hopwa_eligibility guarantees exactly one hopwa_eligible enrollment per household.
      # This filter ensures we deduplicate to households rather than counting every individual.
      scope = relevant_enrollments.where(hopwa_eligible: true)

      # Data Check label row
      sheet.set_row(start_index + 1, label: data_check_label)

      # 1. Continued receiving assistance
      facility_row(sheet, label: 'How many households continued receiving this type of HOPWA assistance into the next year?', index: start_index + 2) do |fac, row|
        filtered = scope.active_after(@report.end_date).where(project_id: fac.id)
        members = heads_of_household_for(filtered)
        row.append_cell_members(members: members)
        facility_counts[fac.id] += members.size
      end

      # 2. Exit destinations
      filters = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ExitDestinationFilter.all_destinations
      exit_counts = add_filtered_enrollment_facilities(sheet, filters: filters, start_index: start_index + 3)
      exit_counts.each { |fac_id, count| facility_counts[fac_id] += count }

      # 3. Individuals died (note: this is counting individuals, not households, but we include in total for data check)
      died_row_index = start_index + 3 + filters.size
      facility_row(sheet, label: 'How many of the HOPWA eligible individuals died?', index: died_row_index) do |fac, row|
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ExitDestinationFilter.deceased
        cell_scope = filter.apply(scope).where(project_id: fac.id)
        members = cell_scope.latest_by_distinct_client_id.as_report_members
        row.append_cell_members(members: members)
        facility_counts[fac.id] += members.size
      end

      # Summary row now uses the pre-calculated counts
      facility_row(sheet, label: 'Housing Outcomes for Households Served by this Activity', index: start_index) do |fac, row|
        row.append_cell_value(value: facility_counts[fac.id])
      end
    end

    def facility_deduplication(sheet, fbh_activity_label:)
      sheet.append_row(label: "#{fbh_activity_label} Deduplication")

      empty_row(sheet, label: "How many households received more than one type of #{fbh_activity_label} for each facility?")

      facility_row(sheet, label: 'Total Deduplicated Household Count') do |fac, row|
        cell_scope = relevant_enrollments.where(project_id: fac.id)
        members = heads_of_household_for(cell_scope)
        row.append_cell_members(members: members)
      end
    end

    def add_filtered_enrollment_facilities(sheet, filters:, start_index: nil)
      facility_counts = Hash.new(0)
      filters.each_with_index do |filter, idx|
        row_index = start_index ? start_index + idx : nil
        facility_row(sheet, label: filter.label, index: row_index) do |fac, row|
          filtered = filter.apply(relevant_enrollments)&.where(project_id: fac.id)
          members = heads_of_household_for(filtered)
          row.append_cell_members(members: members)
          facility_counts[fac.id] += members.size
        end
      end
      facility_counts
    end

    def empty_row(sheet, label:)
      facility_row(sheet, label: label) do |_fac, row|
        row.append_cell_value(value: '')
      end
    end

    def facility_row(sheet, label:, index: nil)
      if index
        # row on a specific index
        sheet.set_row(index, label: label) do |row|
          facilities.each do |facility|
            yield(facility, row)
          end
        end
      else
        # next row
        sheet.append_row(label: label) do |row|
          facilities.each do |facility|
            yield(facility, row)
          end
        end
      end
    end

    def yes_no(bool)
      { true => 'Yes', false => 'No' }[bool]
    end
  end
end
