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
      tbra_households = housing_subsidy_households_for_activity(:tbra)
      pfbh_households = housing_subsidy_households_for_activity(:pfbh)
      st_tfbh_households = housing_subsidy_households_for_activity(:st_tfbh)
      strmu_households = housing_subsidy_households_for_activity(:strmu)
      php_households = housing_subsidy_households_for_activity(:php)

      # row 2
      sheet.append_row(label: 'Total Households Served in ALL Activities from this report for each Activity.') do |row|
        row.append_cell_members(members: household_members(tbra_households))
        row.append_cell_members(members: household_members(pfbh_households))
        row.append_cell_members(members: household_members(st_tfbh_households))
        row.append_cell_members(members: household_members(strmu_households))
        row.append_cell_members(members: household_members(php_households))
        row.append_cell_members(members: household_members(housing_info_households))
        row.append_cell_members(members: household_members(supportive_services_households))
        row.append_cell_members(members: household_members(other_competitive_households))
      end
    end

    def housing_subsidy_deduplication_section(sheet)
      # row 3
      sheet.append_row(label: 'Housing Subsidy Assistance Household Count Deduplication')
      housing_subsidy_households = all_housing_subsidy_households

      # row 4
      sheet.append_row(label: 'Total Housing Subsidy Assistance (from the TBRA, P-FBH, ST-TFBH, STRMU, PHP, Other Competitive Activity counts above)') do |row|
        count_with_duplicates = [:tbra, :strmu, :php].map { |type| housing_subsidy_households_for_activity(type).count }.sum
        row.append_cell_members(members: household_members(housing_subsidy_households), value: count_with_duplicates)
      end

      duplicated_households = find_duplicated_households_across_activities

      # row 5
      sheet.append_row(label: 'How many households received more than one type of HOPWA Housing Subsidy Assistance for TBRA, P-FBH, ST-TFBH, STRMU, PHP, Other Competitive Activity?') do |row|
        row.append_cell_members(members: household_members(duplicated_households))
      end

      # row 6
      sheet.append_row(label: 'Total Unduplicated Housing Subsidy Assistance Household Count') do |row|
        row.append_cell_members(members: household_members(housing_subsidy_households))
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
        case_management_services = @report.hopwa_caper_services.hud_services.
          where(date_provided: @report.start_date..@report.end_date).
          where(record_type: 143, type_provided: 3)
        cm_household_ids = case_management_services.select(:report_household_id)

        maintained_contact_households = housing_subsidy_households.where(atc_maintained_contact: true).
          or(housing_subsidy_households.where(report_household_id: cm_household_ids))

        row.append_cell_members(members: household_members(maintained_contact_households))
      end

      # Row 11
      sheet.append_row(label: 'How many households developed a housing plan for maintaining or establishing stable housing?') do |row|
        housing_plan_households = housing_subsidy_households.where(atc_housing_plan: true)
        row.append_cell_members(members: household_members(housing_plan_households))
      end

      # Row 12
      sheet.append_row(label: 'How many households accessed and maintained medical insurance and/or assistance?') do |row|
        insurance_households = housing_subsidy_households.where.overlaps(
          household_medical_insurance_types: ['InsuranceFromAnySource', 'ADAP', 'RyanWhiteMedDent'],
        )
        row.append_cell_members(members: household_members(insurance_households))
      end

      # Row 13
      primary_health_contact_households = housing_subsidy_households.where(atc_primary_health_contact: true)
      sheet.append_row(label: 'How many households had contact with a primary health care provider?') do |row|
        row.append_cell_members(members: household_members(primary_health_contact_households))
      end

      # Row 14
      sheet.append_row(label: 'How many households accessed or maintained qualification for sources of income?') do |row|
        income_households = housing_subsidy_households.where.overlaps(
          household_income_benefit_source_types: ['IncomeFromAnySource'],
        )
        row.append_cell_members(members: household_members(income_households))
      end

      # Row 15
      sheet.append_row(label: 'How many households obtained/maintained an income-producing job during the program year (with or without any HOPWA-related assistance)?') do |row|
        earned_income_households = housing_subsidy_households.where.overlaps(
          household_income_benefit_source_types: ['Earned'],
        )
        row.append_cell_members(members: household_members(earned_income_households))
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

      case_management_services = @report.hopwa_caper_services.hud_services.
        where(date_provided: @report.start_date..@report.end_date).
        where(record_type: 143, type_provided: 3)

      case_management_households = housing_subsidy_households.
        where(report_household_id: case_management_services.select(:report_household_id).distinct)
      # row 18
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Funded Case Management?') do |row|
        row.append_cell_members(members: household_members(case_management_households))
      end

      supportive_services = @report.hopwa_caper_services.hud_services.
        where(date_provided: @report.start_date..@report.end_date).
        where(record_type: 143)

      supportive_service_households = housing_subsidy_households.
        where(report_household_id: supportive_services.select(:report_household_id).distinct)
      # row 19
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Supportive Services?') do |row|
        row.append_cell_members(members: household_members(supportive_service_households))
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
      service_type_filters = HopwaCaper::Generators::Fy2026::ServiceFilters::SupportiveServiceTypeFilter
      record_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_service

      record_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date..@report.end_date).
        where(type_provided: service_type_filters.supportive_service_codes).
        select(:report_household_id).
        distinct
    end

    def other_competitive_households
      # Other competitive activities - may need to be configured or calculated
      @report.hopwa_caper_enrollments.none
    end

    def all_housing_subsidy_households
      tbra_ids = housing_subsidy_households_for_activity(:tbra).select(:report_household_id).distinct.pluck(:report_household_id)
      strmu_ids = housing_subsidy_households_for_activity(:strmu).select(:report_household_id).distinct.pluck(:report_household_id)
      php_ids = housing_subsidy_households_for_activity(:php).select(:report_household_id).distinct.pluck(:report_household_id)
      other_ids = other_competitive_households.select(:report_household_id).distinct.pluck(:report_household_id)

      all_household_ids = (tbra_ids + strmu_ids + php_ids + other_ids).uniq

      @report.hopwa_caper_enrollments.where(report_household_id: all_household_ids)
    end

    def find_duplicated_households_across_activities
      tbra_ids = housing_subsidy_households_for_activity(:tbra).select(:report_household_id).distinct
      strmu_ids = housing_subsidy_households_for_activity(:strmu).select(:report_household_id).distinct
      php_ids = housing_subsidy_households_for_activity(:php).select(:report_household_id).distinct
      other_ids = other_competitive_households.select(:report_household_id).distinct

      # Find households that appear in multiple activity types
      all_ids = [tbra_ids, strmu_ids, php_ids, other_ids].compact
      return @report.hopwa_caper_enrollments.none if all_ids.empty?

      # Count occurrences of each household_id across all activity types
      household_counts = {}
      all_ids.each do |ids|
        ids.pluck(:report_household_id).each do |household_id|
          household_counts[household_id] = (household_counts[household_id] || 0) + 1
        end
      end

      duplicated_ids = household_counts.select { |_id, count| count > 1 }.keys
      return @report.hopwa_caper_enrollments.none if duplicated_ids.empty?

      @report.hopwa_caper_enrollments.where(report_household_id: duplicated_ids)
    end

    def household_members(enrollments_or_household_ids)
      return [] if enrollments_or_household_ids.blank?

      if enrollments_or_household_ids.is_a?(ActiveRecord::Relation) && enrollments_or_household_ids.model == HopwaCaper::Enrollment
        household_ids = enrollments_or_household_ids.select(:report_household_id)
      else
        household_ids = enrollments_or_household_ids
      end

      @report.hopwa_caper_enrollments.head_of_household.
        where(report_household_id: household_ids).
        latest_by_distinct_client_id.
        as_report_members
    end
  end
end
