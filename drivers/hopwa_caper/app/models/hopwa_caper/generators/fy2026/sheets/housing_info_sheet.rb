# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class HousingInfoSheet < BaseProgramSheet
    QUESTION_NUMBER = 'Q5: Housing Information Services'
    QUESTION_NUMBERS = ['Q5'].freeze
    SHEET_TITLE = 'Complete for all households served with HOPWA-funded Housing Information Services by your organization in the reporting year.'
    HOUSING_INFO_CATEGORY_NAME = 'HOPWA Housing Information'

    CONTENTS = [
      { method: :households_served_sheet, label: 'Households Served by this Activity' },
      { method: :expenditures_sheet, label: 'Housing Information Services Expenditures' },
    ].freeze

    protected

    def relevant_enrollments
      housing_info_enrollments
    end

    def households_served_sheet(sheet)
      add_household_enrollments_row(
        sheet,
        label: 'How many households were served with housing information services?',
        enrollments: housing_info_enrollments,
      )
    end

    def expenditures_sheet(sheet)
      sheet.append_row(label: 'What were the HOPWA funds expended for Housing Information Services?')
    end

    private

    def housing_info_enrollments
      @housing_info_enrollments ||= begin
        hopwa_table = HopwaCaper::Enrollment.table_name
        enrollment_table = GrdaWarehouse::Hud::Enrollment.table_name
        custom_service_table = Hmis::Hud::CustomService.table_name
        custom_service_type_table = Hmis::Hud::CustomServiceType.table_name
        custom_service_category_table = Hmis::Hud::CustomServiceCategory.table_name

        joins_sql = <<~SQL.squish
          INNER JOIN "#{enrollment_table}" housing_info_enrollment
            ON housing_info_enrollment.id = #{hopwa_table}.enrollment_id
          INNER JOIN "#{custom_service_table}" housing_info_custom_services
            ON housing_info_custom_services."EnrollmentID" = housing_info_enrollment."EnrollmentID"
            AND housing_info_custom_services."PersonalID" = housing_info_enrollment."PersonalID"
            AND housing_info_custom_services.data_source_id = housing_info_enrollment.data_source_id
          INNER JOIN "#{custom_service_type_table}" housing_info_custom_service_types
            ON housing_info_custom_service_types.id = housing_info_custom_services.custom_service_type_id
          INNER JOIN "#{custom_service_category_table}" housing_info_custom_service_categories
            ON housing_info_custom_service_categories.id = housing_info_custom_service_types.custom_service_category_id
        SQL

        HopwaCaper::Enrollment.
          where(report_instance_id: @report.id).
          joins(joins_sql).
          where(housing_info_custom_services: { DateProvided: @report.start_date..@report.end_date }).
          where(housing_info_custom_service_categories: { name: HOUSING_INFO_CATEGORY_NAME }).
          select(:report_household_id).
          distinct
      end
    end
  end
end
