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

    def run_question!
      @report.start(QUESTION_NUMBER, 'Q7')

      question_sheet(question: 'Q7') do |sheet|
        activity_review_section(sheet)
        housing_subsidy_deduplication_section(sheet)
        access_to_care_section(sheet)
        subsidy_with_supportive_service_section(sheet)
      end

      @report.complete(QUESTION_NUMBER)
    end

    protected

    def activity_review_section(sheet)
      sheet.append_row(label: 'Total Households Served in ALL Activities from this report for each Activity.')

      tbra_households = housing_subsidy_households_for_activity(:tbra)
      pfbh_households = housing_subsidy_households_for_activity(:pfbh)
      st_tfbh_households = housing_subsidy_households_for_activity(:st_tfbh)
      strmu_households = housing_subsidy_households_for_activity(:strmu)
      php_households = housing_subsidy_households_for_activity(:php)
      housing_info_households = housing_info_households
      supportive_services_households = supportive_services_households
      other_competitive_households = other_competitive_households

      sheet.append_row(label: nil) do |row|
        row.append_cell_value(value: nil)
        row.append_cell_value(value: 'TBRA')
        row.append_cell_value(value: 'P-FBH')
        row.append_cell_value(value: 'ST-TFBH')
        row.append_cell_value(value: 'STRMU')
        row.append_cell_value(value: 'PHP')
        row.append_cell_value(value: 'Housing Info')
        row.append_cell_value(value: 'SUPP SVC')
        row.append_cell_value(value: 'Other Competitive Activity')
      end

      sheet.append_row(label: 'Total Households') do |row|
        row.append_cell_value(value: nil)
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
      sheet.append_row(label: nil)

      housing_subsidy_households = all_housing_subsidy_households
      total_housing_subsidy = household_members(housing_subsidy_households)

      sheet.append_row(label: 'Total Housing Subsidy Assistance (from the TBRA, P-FBH, ST-TFBH, STRMU, PHP, Other Competitive Activity counts above)') do |row|
        row.append_cell_members(members: total_housing_subsidy)
      end

      duplicated_households = find_duplicated_households_across_activities
      duplicated_count = household_members(duplicated_households)

      sheet.append_row(label: 'Of the households in row 2, count distinct households that appear in more than one column') do |row|
        row.append_cell_members(members: duplicated_count)
      end

      unduplicated_households = housing_subsidy_households.where.not(report_household_id: duplicated_households.select(:report_household_id))
      unduplicated_count = household_members(unduplicated_households)

      sheet.append_row(label: 'Total Unduplicated Housing Subsidy Assistance Household') do |row|
        row.append_cell_members(members: unduplicated_count)
      end
    end

    def access_to_care_section(sheet)
      sheet.append_row(label: nil)
      sheet.append_row(label: 'Complete HOPWA Outcomes for Access to Care and Support for all households served with HOPWA housing assistance and "other competitive activities" in the reporting year.')

      housing_subsidy_households = all_housing_subsidy_households

      maintained_contact_households = housing_subsidy_households.where(atc_maintained_contact: true)
      sheet.append_row(label: 'How many households had contact with a case manager?') do |row|
        row.append_cell_members(members: household_members(maintained_contact_households))
      end

      housing_plan_households = housing_subsidy_households.where(atc_housing_plan: true)
      sheet.append_row(label: 'How many households developed a housing plan for maintaining or establishing stable housing?') do |row|
        row.append_cell_members(members: household_members(housing_plan_households))
      end

      enrollment_ids = housing_subsidy_households.pluck(:enrollment_id).uniq
      insurance_enrollment_ids = GrdaWarehouse::Hud::IncomeBenefit.
        where(EnrollmentID: enrollment_ids).
        where("InformationDate <= ?", @report.end_date).
        where("InsuranceFromAnySource = 1 OR ADAP = 1 OR RyanWhiteMedDent = 1").
        select(:EnrollmentID).
        distinct.
        pluck(:EnrollmentID)
      insurance_households = housing_subsidy_households.where(enrollment_id: insurance_enrollment_ids)
      sheet.append_row(label: 'How many households accessed and maintained medical insurance and/or assistance?') do |row|
        row.append_cell_members(members: household_members(insurance_households))
      end

      primary_health_contact_households = housing_subsidy_households.where(atc_primary_health_contact: true)
      sheet.append_row(label: 'How many households had contact with a primary health care provider?') do |row|
        row.append_cell_members(members: household_members(primary_health_contact_households))
      end

      income_enrollment_ids = GrdaWarehouse::Hud::IncomeBenefit.
        where(EnrollmentID: enrollment_ids).
        where("InformationDate <= ?", @report.end_date).
        where("IncomeFromAnySource = 1").
        select(:EnrollmentID).
        distinct.
        pluck(:EnrollmentID)
      income_households = housing_subsidy_households.where(enrollment_id: income_enrollment_ids)
      sheet.append_row(label: 'How many households accessed or maintained qualification for sources of income?') do |row|
        row.append_cell_members(members: household_members(income_households))
      end

      earned_income_enrollment_ids = GrdaWarehouse::Hud::IncomeBenefit.
        where(EnrollmentID: enrollment_ids).
        where("InformationDate <= ?", @report.end_date).
        where("Earned = 1").
        select(:EnrollmentID).
        distinct.
        pluck(:EnrollmentID)
      earned_income_households = housing_subsidy_households.where(enrollment_id: earned_income_enrollment_ids)
      sheet.append_row(label: 'How many households obtained/maintained an income-producing job during the program year (with or without any HOPWA-related assistance)?') do |row|
        row.append_cell_members(members: household_members(earned_income_households))
      end
    end

    def subsidy_with_supportive_service_section(sheet)
      sheet.append_row(label: nil)
      sheet.append_row(label: 'Subsidy Assistance with Supportive Service, Funded Case Management Questions.')

      housing_subsidy_households = all_housing_subsidy_households

      case_management_services = @report.hopwa_caper_services.hud_services.
        where(date_provided: @report.start_date..@report.end_date).
        where(record_type: 143, type_provided: 3)

      case_management_households = housing_subsidy_households.
        where(report_household_id: case_management_services.select(:report_household_id).distinct)
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Funded Case Management?') do |row|
        row.append_cell_members(members: household_members(case_management_households))
      end

      supportive_services = @report.hopwa_caper_services.hud_services.
        where(date_provided: @report.start_date..@report.end_date).
        where(record_type: 143)

      supportive_service_households = housing_subsidy_households.
        where(report_household_id: supportive_services.select(:report_household_id).distinct)
      sheet.append_row(label: 'How many households received any type of HOPWA Housing Subsidy Assistance and HOPWA Supportive Services?') do |row|
        row.append_cell_members(members: household_members(supportive_service_households))
      end
    end

    private

    def housing_subsidy_households_for_activity(activity_type)
      case activity_type
      when :tbra
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.tbra_hopwa
        overlapping_enrollments(filter.apply(@report.hopwa_caper_enrollments))
      when :strmu
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.strmu_hopwa
        overlapping_enrollments(filter.apply(@report.hopwa_caper_enrollments))
      when :php
        filter = HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.php_hopwa
        overlapping_enrollments(filter.apply(@report.hopwa_caper_enrollments))
      when :pfbh, :st_tfbh
        # P-FBH and ST-TFBH may be part of TBRA or PHP - for now return empty scope
        @report.hopwa_caper_enrollments.none
      else
        @report.hopwa_caper_enrollments.none
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
      record_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_service
      record_filter.apply(@report.hopwa_caper_services).
        where(date_provided: @report.start_date..@report.end_date).
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
      return [] if enrollments_or_household_ids.none?

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
