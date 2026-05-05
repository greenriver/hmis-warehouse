# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class PFbhSheet < BaseFbhSheet
    QUESTION_NUMBER = 'Q10: P-FBH'
    QUESTION_NUMBERS = ['Q10'].freeze
    SHEET_TITLE = 'Complete this section for all Households served with HOPWA Permanent Facility-Based Housing assistance by your organization in the reporting year. NOTE: Scattered-Site Facilities may be reported as one Facility.'

    def run_question!
      question_number = self.class::QUESTION_NUMBER
      tables = self.class::QUESTION_NUMBERS
      @report.start(question_number, tables)
      raise unless tables.one?

      question_sheet(question: tables.first) do |sheet|
        add_header(sheet)

        fbh_activity_label = 'Permanent'
        facility_information(sheet)
        facility_leasing_expenditures(sheet, fbh_activity_label: fbh_activity_label)
        facility_operating_expenditures(sheet, fbh_activity_label: fbh_activity_label)
        p_fbh_other_housing_support(sheet)
        facility_deduplication(sheet, fbh_activity_label: 'P-FBH')
        income_levels(
          sheet,
          spreadsheet_row: 21,
          data_check_label: 'Data Check: Sum of 23-25 as shown in Row 21 must be = to Row 20',
        )
        income_sources(
          sheet,
          label: 'Sources of Income for Households Served by this Activity Data Check: Sum of 28-40 as shown in Row 27 must be = or > than Row 20',
        )
        medical_insurance(
          sheet,
          label: 'Medical Insurance/Assistance for Households Served by this Activity Data Check: If 43-48 are all "0", provide explanation in P-FBH section of Data Quality Notes Tab.',
        )
        longevity_for_households(
          sheet,
          spreadsheet_row: 49,
          data_check_label: 'Data Check: Sum of 51-55 as shown in Row 49 must be = to Row 20',
          activity_label: 'permanent facility-based housing',
        )
        health_outcomes_for_individuals(sheet)
        housing_outcomes(
          sheet,
          spreadsheet_row: 59,
          data_check_label: 'Data Check: Sum of 61-74 as shown in Row 59 must be = to Row 20.',
        )
      end

      @report.complete(question_number)
    end

    protected

    def p_fbh_other_housing_support(sheet)
      # row 14
      sheet.append_row(label: 'Other Housing Support -- Households and Expenditures Served by this Activity Expenditures total should include overhead (staff costs, fringe, etc.).')
      # row 15
      empty_row(sheet, label: 'How many households received Other types of Permanent Facility-Based Housing support for each facility?')
      # row 16
      empty_row(sheet, label: 'What were the HOPWA funds expended for Other types of Permanent Facility-Based Housing for each facility?')
      # row 17
      empty_row(sheet, label: 'For households served with Other Permanent Facility-Based Housing, what type of service were they provided? (150 characters)')
    end

    def program_filter
      HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.
        p_fbh(range: @report.report_range)
    end

    def health_outcomes_for_individuals(sheet)
      # row 56
      sheet.append_row(label: 'Health Outcomes for HOPWA-Eligible Individuals Served by this Activity Data Check: If 57 and/or 58 are "0", provide explanation in "P-FBH" section of Data Quality Notes Tab.')

      # row 57
      facility_row(sheet, label: 'How many HOPWA-eligible individuals served with PFBH this year have ever been prescribed Anti-Retroviral Therapy, by facility?') do |fac, row|
        cell_scope = relevant_enrollments.where(project_id: fac.id, hopwa_eligible: true, ever_prescribed_anti_retroviral_therapy: true)
        row.append_cell_members(members: cell_scope.as_report_members)
      end

      # row 58
      facility_row(sheet, label: 'How many HOPWA-eligible persons served with PFBH have shown an improved viral load or achieved viral suppression, by facility?') do |fac, row|
        cell_scope = relevant_enrollments.where(project_id: fac.id, hopwa_eligible: true, viral_load_suppression: true)
        row.append_cell_members(members: cell_scope.as_report_members)
      end
    end
  end
end
