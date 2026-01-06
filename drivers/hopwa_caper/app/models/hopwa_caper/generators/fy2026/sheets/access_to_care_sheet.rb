# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class AccessToCareSheet < Base
    QUESTION_NUMBER = 'Q7: Access To Care'
    QUESTION_NUMBERS = ['Q7'].freeze
    SHEET_TITLE = 'Access to Care (ATC)'

    # Activities that count towards Housing Subsidy Assistance
    HOUSING_SUBSIDY_ACTIVITIES = [:tbra, :pfbh, :st_tfbh, :strmu, :php, :other_competitive].freeze

    CONTENTS = [
      { method: :activity_review_section, label: 'Total Households Served in ALL Activities from this report for each Activity.' },
    ].freeze

    def run_question!
      question_number = self.class::QUESTION_NUMBER
      tables = self.class::QUESTION_NUMBERS
      @report.start(question_number, tables)

      question_sheet(question: tables.first) do |sheet|
        add_sheet_header(sheet)
        activity_review_section(sheet)
        housing_subsidy_deduplication_section(sheet)
        access_to_care_section(sheet)
        subsidy_with_supportive_service_section(sheet)
      end

      @report.complete(question_number)
    end

    protected

    def add_sheet_header(sheet)
      # row 1
      sheet.add_header(col: 'A', label: 'Activity Review')
      sheet.add_header(col: 'B', label: 'TBRA')
      sheet.add_header(col: 'C', label: 'P-FBH')
      sheet.add_header(col: 'D', label: 'ST-TFBH')
      sheet.add_header(col: 'E', label: 'STRMU')
      sheet.add_header(col: 'F', label: 'PHP')
      sheet.add_header(col: 'G', label: 'Housing Info')
      sheet.add_header(col: 'H', label: 'SUPP SVC')
      sheet.add_header(col: 'I', label: 'Other Competitive Activity')
    end

    def activity_review_section(sheet)
      # row 2
      sheet.append_row(label: 'Total Households Served in ALL Activities from this report for each Activity.') do |row|
        row.append_cell_members(members: activity_household_members(:tbra))
        row.append_cell_members(members: activity_household_members(:pfbh))
        row.append_cell_members(members: activity_household_members(:st_tfbh))
        row.append_cell_members(members: activity_household_members(:strmu))
        row.append_cell_members(members: activity_household_members(:php))
        row.append_cell_members(members: heads_of_household_for(housing_info_households))
        row.append_cell_members(members: heads_of_household_for(supportive_services_households))
        row.append_cell_members(members: activity_household_members(:other_competitive))
      end
    end

    def housing_subsidy_deduplication_section(sheet)
      # row 3
      sheet.append_row(label: 'Housing Subsidy Assistance Household Count Deduplication')
      housing_subsidy_households = all_housing_subsidy_households

      # row 4
      sheet.append_row(label: 'Total Housing Subsidy Assistance (from the TBRA, P-FBH, ST-TFBH, STRMU, PHP, Other Competitive Activity counts above)') do |row|
        count_with_duplicates = HOUSING_SUBSIDY_ACTIVITIES.sum do |type|
          activity_household_members(type).size
        end
        # just include the value as members would contain duplicates
        row.append_cell_value(value: count_with_duplicates)
      end

      # row 5
      sheet.append_row(label: 'How many households received more than one type of HOPWA Housing Subsidy Assistance for TBRA, P-FBH, ST-TFBH, STRMU, PHP, Other Competitive Activity?') do |row|
        duplicated_households = find_duplicated_households_across_activities
        row.append_cell_members(members: heads_of_household_for(duplicated_households))
      end

      # row 6
      sheet.append_row(label: 'Total Unduplicated Housing Subsidy Assistance Household Count') do |row|
        row.append_cell_members(members: heads_of_household_for(housing_subsidy_households))
      end
    end

    def access_to_care_section(sheet)
      # row 7
      sheet.append_row(label: 'Access to Care (ATC)')
      # row 8
      sheet.append_row(label: 'Complete HOPWA Outcomes for Access to Care and Support for all households served with HOPWA housing assistance and "other competitive activities" in the reporting year.')
      # row 9
      sheet.append_row(label: 'Questions') do |row|
        row.append_cell_value(value: 'This Report')
      end

      housing_subsidy_households = all_housing_subsidy_households

      # Row 10
      sheet.append_row(label: 'How many households had contact with a case manager?') do |row|
        cm_hoh_client_ids = @report.hopwa_caper_enrollments.
          head_of_household.
          where(report_household_id: case_management_services.select(:report_household_id)).
          select(:destination_client_id)

        maintained_contact_households = housing_subsidy_households.where(atc_maintained_contact: true).
          or(housing_subsidy_households.where(destination_client_id: cm_hoh_client_ids))

        row.append_cell_members(members: heads_of_household_for(maintained_contact_households))
      end

      # Row 11
      sheet.append_row(label: 'How many households developed a housing plan for maintaining or establishing stable housing?') do |row|
        housing_plan_households = housing_subsidy_households.where(atc_housing_plan: true)
        row.append_cell_members(members: heads_of_household_for(housing_plan_households))
      end

      # Row 12
      sheet.append_row(label: 'How many households accessed and maintained medical insurance and/or assistance?') do |row|
        # Any recorded insurance type counts as having medical insurance/assistance
        insurance_filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::MedicalInsuranceFilter.any_insurance
        insurance_households = insurance_filter.apply(housing_subsidy_households)
        row.append_cell_members(members: heads_of_household_for(insurance_households))
      end

      # Row 13
      primary_health_contact_households = housing_subsidy_households.where(atc_primary_health_contact: true)
      sheet.append_row(label: 'How many households had contact with a primary health care provider?') do |row|
        row.append_cell_members(members: heads_of_household_for(primary_health_contact_households))
      end

      # Row 14
      sheet.append_row(label: 'How many households accessed or maintained qualification for sources of income?') do |row|
        # Any recorded income source counts as having sources of income
        income_filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitSourceFilter.any_income
        income_households = income_filter.apply(housing_subsidy_households)
        row.append_cell_members(members: heads_of_household_for(income_households))
      end

      # Row 15
      sheet.append_row(label: 'How many households obtained/maintained an income-producing job during the program year (with or without any HOPWA-related assistance)?') do |row|
        earned_income_filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::IncomeBenefitSourceFilter.earned_income
        earned_income_households = earned_income_filter.apply(housing_subsidy_households)
        row.append_cell_members(members: heads_of_household_for(earned_income_households))
      end
    end

    def subsidy_with_supportive_service_section(sheet)
      # Row 16
      sheet.append_row(label: 'Subsidy Assistance with Supportive Service, Funded Case Management')

      # row 17
      sheet.append_row(label: 'Questions') do |row|
        row.append_cell_value(value: 'This Report')
      end

      housing_subsidy_households = all_housing_subsidy_households

      # row 18
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Funded Case Management?') do |row|
        cm_hoh_client_ids = @report.hopwa_caper_enrollments.
          head_of_household.
          where(report_household_id: case_management_services.select(:report_household_id)).
          select(:destination_client_id)

        case_management_households = housing_subsidy_households.
          where(destination_client_id: cm_hoh_client_ids)
        row.append_cell_members(members: heads_of_household_for(case_management_households))
      end

      # row 19
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Supportive Services?') do |row|
        ss_hoh_client_ids = @report.hopwa_caper_enrollments.
          head_of_household.
          where(report_household_id: supportive_services.select(:report_household_id)).
          select(:destination_client_id)

        supportive_service_households = housing_subsidy_households.
          where(destination_client_id: ss_hoh_client_ids)
        row.append_cell_members(members: heads_of_household_for(supportive_service_households))
      end
    end

    def housing_subsidy_households_for_activity(activity_type)
      case activity_type
      when :tbra
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa
        overlapping_enrollments(filter.apply(@report.hopwa_caper_enrollments))
      when :strmu
        enrollments = overlapping_enrollments(
          HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa.apply(@report.hopwa_caper_enrollments),
        )
        service_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_financial_assistance
        relevant_services = service_filter.apply(@report.hopwa_caper_services).
          where(date_provided: @report.start_date..@report.end_date).
          joins(:enrollment).merge(enrollments)
        enrollments.where(report_household_id: relevant_services.select(:report_household_id))
      when :php
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.php_hopwa
        overlapping_enrollments(filter.apply(@report.hopwa_caper_enrollments))
      when :pfbh, :st_tfbh
        # P-FBH and ST-TFBH may be part of TBRA or PHP - for now return empty scope
        @report.hopwa_caper_enrollments.none
      when :other_competitive
        other_competitive_households
      else
        raise ArgumentError, "invalid activity_type #{activity_type}"
      end
    end

    def housing_info_households
      @report.hopwa_caper_services.custom_services.
        where(date_provided: @report.start_date..@report.end_date).
        where(service_category_name: 'HOPWA Housing Information').
        select(:report_household_id).
        distinct
    end

    def supportive_services_households
      supportive_services.
        select(:report_household_id).
        distinct
    end

    def other_competitive_households
      # Other competitive activities - may need to be configured or calculated
      @report.hopwa_caper_enrollments.none
    end

    private

    def supportive_services
      service_type_filters = HopwaCaper::Generators::Fy2026::ServiceFilters::SupportiveServiceTypeFilter
      record_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_service

      record_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date..@report.end_date).
        where(type_provided: service_type_filters.supportive_service_codes)
    end

    def case_management_services
      case_management_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::SupportiveServiceTypeFilter.case_management
      supportive_services.where(type_provided: case_management_filter.codes)
    end

    def all_housing_subsidy_households
      hoh_client_ids = HOUSING_SUBSIDY_ACTIVITIES.flat_map do |activity_type|
        activity_household_scope(activity_type).pluck(:destination_client_id)
      end.uniq

      @report.hopwa_caper_enrollments.
        head_of_household.
        where(destination_client_id: hoh_client_ids).
        latest_by_distinct_client_id
    end

    def find_duplicated_households_across_activities
      # Collect client IDs of HOHs from each activity type
      activity_hoh_client_ids = HOUSING_SUBSIDY_ACTIVITIES.map do |activity_type|
        activity_household_scope(activity_type).pluck(:destination_client_id)
      end

      return @report.hopwa_caper_enrollments.none if activity_hoh_client_ids.all?(&:empty?)

      # Find HOHs appearing in multiple activity types
      duplicated_hoh_client_ids = activity_hoh_client_ids.
        flatten.
        group_by(&:itself).
        select { |_id, occurrences| occurrences.size > 1 }.
        keys

      return @report.hopwa_caper_enrollments.none if duplicated_hoh_client_ids.empty?

      @report.hopwa_caper_enrollments.
        head_of_household.
        where(destination_client_id: duplicated_hoh_client_ids).
        latest_by_distinct_client_id
    end

    def activity_household_members(activity_type)
      heads_of_household_for(housing_subsidy_households_for_activity(activity_type))
    end

    def activity_household_scope(activity_type)
      heads_of_household_scope_for(housing_subsidy_households_for_activity(activity_type))
    end
  end
end
