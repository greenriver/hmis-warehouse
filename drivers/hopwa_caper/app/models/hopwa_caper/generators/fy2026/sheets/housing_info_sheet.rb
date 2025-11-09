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
        hopwa = HopwaCaper::Enrollment.arel_table
        enrollment = GrdaWarehouse::Hud::Enrollment.arel_table
        custom_service = Hmis::Hud::CustomService.arel_table
        custom_service_type = Hmis::Hud::CustomServiceType.arel_table
        custom_service_category = Hmis::Hud::CustomServiceCategory.arel_table

        # Join HopwaCaper::Enrollment -> GrdaWarehouse::Hud::Enrollment via enrollment_id
        join_enrollment = hopwa.join(enrollment, Arel::Nodes::InnerJoin).
          on(enrollment[:id].eq(hopwa[:enrollment_id])).
          join_sources

        # Join Enrollment -> CustomService via composite key (EnrollmentID, PersonalID, data_source_id)
        join_custom_service = enrollment.join(custom_service, Arel::Nodes::InnerJoin).
          on(
            custom_service[:EnrollmentID].eq(enrollment[:EnrollmentID]).
            and(custom_service[:PersonalID].eq(enrollment[:PersonalID])).
            and(custom_service[:data_source_id].eq(enrollment[:data_source_id])),
          ).
          join_sources

        # Join CustomService -> CustomServiceType via association
        join_service_type = custom_service.join(custom_service_type, Arel::Nodes::InnerJoin).
          on(custom_service_type[:id].eq(custom_service[:custom_service_type_id])).
          join_sources

        # Join CustomServiceType -> CustomServiceCategory via association
        join_category = custom_service_type.join(custom_service_category, Arel::Nodes::InnerJoin).
          on(custom_service_category[:id].eq(custom_service_type[:custom_service_category_id])).
          join_sources

        HopwaCaper::Enrollment.
          where(report_instance_id: @report.id).
          joins(join_enrollment, join_custom_service, join_service_type, join_category).
          where(custom_service[:DateProvided].in(@report.start_date..@report.end_date)).
          where(custom_service_category[:name].eq(HOUSING_INFO_CATEGORY_NAME)).
          select(:report_household_id).
          distinct
      end
    end
  end
end
