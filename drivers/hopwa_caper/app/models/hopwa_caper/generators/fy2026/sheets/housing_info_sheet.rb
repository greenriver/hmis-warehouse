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
      @housing_info_enrollments ||= HopwaCaper::Service.
        where(report_instance_id: @report.id).
        where(service_source: HopwaCaper::Service::CUSTOM_SERVICE_SOURCE).
        where(date_provided: @report.start_date..@report.end_date).
        where(service_category_name: HOUSING_INFO_CATEGORY_NAME).
        select(:report_household_id).
        distinct
    end
  end
end
