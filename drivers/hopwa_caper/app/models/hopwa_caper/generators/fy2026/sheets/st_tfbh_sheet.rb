# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class StTfbhSheet < BaseFbhSheet
    QUESTION_NUMBER = 'Q9: ST-TFBH'
    QUESTION_NUMBERS = ['Q9'].freeze
    SHEET_TITLE = 'Complete this section for Facilities, Households served with HOPWA Short-Term or Transitional Facility-Based Housing assistance by your organization in the reporting year. Note: Scattered-Site Facilities may be reported as one Facility. Examples include Short-Term and Transitional Housing Types, Facility Based Housing with a tenure of fewer than 24 months, short-term treatment or health facilities, hotel-motel vouchers.'

    def run_question!
      question_number = self.class::QUESTION_NUMBER
      tables = self.class::QUESTION_NUMBERS
      @report.start(question_number, tables)
      raise unless tables.one?

      question_sheet(question: tables.first) do |sheet|
        add_header(sheet)

        fbh_activity_label = 'Transitional/Short-Term'
        facility_information(sheet)
        facility_leasing_expenditures(sheet, fbh_activity_label: fbh_activity_label)
        facility_operating_expenditures(sheet, fbh_activity_label: fbh_activity_label)
        facility_hotel_motel_expenditures(sheet)
        st_tfbh_other_housing_support(sheet)
        facility_deduplication(sheet, fbh_activity_label: 'ST-TFBH')
        income_levels(
          sheet,
          spreadsheet_row: 24,
          data_check_label: 'Data Check: Sum of 26-28 as shown in Row 24 must be = to Row 23',
        )
        income_sources(
          sheet,
          label: 'Sources of Income for Households Served by this Activity Data Check: Sum of 31-43 as shown in Row 30 must be = to or > than Row 23',
        )
        medical_insurance(
          sheet,
          label: 'Medical Insurance/Assistance for Households Served by this Activity Data Check: If 46-51 are all "0", provide explanation in ST-TFBH section of Data Quality Notes Tab.',
        )
        longevity_for_households(
          sheet,
          spreadsheet_row: 52,
          data_check_label: 'Data Check: Sum of 54-58 as shown in Row 52 must be = to Row 23',
          activity_label: 'short-term/transitional facility-based housing',
        )
        housing_outcomes(
          sheet,
          spreadsheet_row: 59,
          data_check_label: 'Data Check: Sum of 61-74 as shown in Row 59 must be = to Row 23',
        )
      end

      @report.complete(question_number)
    end

    protected

    def program_filter
      HopwaCaper::Generators::Fy2026::EnrollmentFilters::ProjectFunderFilter.
        st_tfbh(range: @report.report_range)
    end

    def facility_hotel_motel_expenditures(sheet)
      # row 14
      sheet.append_row(label: 'Hotel-Motel -- Households and Expenditures Served by this Activity Expenditures total should include overhead (staff costs, fringe, etc.).')
      # row 15
      empty_row(sheet, label: 'How many households received Hotel-Motel cost support for each facility?')
      # row 16
      empty_row(sheet, label: 'What were the HOPWA funds expended for Hotel-Motel Costs for each facility?')
    end

    def st_tfbh_other_housing_support(sheet)
      # row 17
      sheet.append_row(label: 'Other Housing Support -- Households and Expenditures Served by this Activity Expenditures total should include overhead (staff costs, fringe, etc.).')
      # row 18
      empty_row(sheet, label: 'How many households received Other types of Transitional/Short-Term Facility-Based Housing support for each facility?')
      # row 19
      empty_row(sheet, label: 'What were the HOPWA funds expended for Other types of Transitional/Short-Term Facility-Based Housing for each facility?')
      # row 20
      empty_row(sheet, label: 'For households served with Other Transitional/Short-Term Facility-Based Housing, what type of service were they provided? (150 characters)')
    end
  end
end
