###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# common questions and behavior for TBRU, STRMU, PHP
module HopwaCaper::Generators::Fy2024::Sheets
  class BaseProgramSheet < Base
    def run_question!
      question_number = self.class::QUESTION_NUMBER
      tables = self.class::QUESTION_NUMBERS
      contents = self.class::CONTENTS
      @report.start(question_number, tables)
      raise unless tables.one?

      question_sheet(question: tables.first) do |sheet|
        add_two_col_header(sheet)
        contents.each do |opts|
          opts => {method:, label:}
          # header
          sheet.append_row(label: label) if label
          send(method, sheet)
        end
      end
      @report.complete(question_number)
    end

    protected

    # add a labeled row, enrollments are counted only their HOH
    def add_household_enrollments_row(sheet, label:, enrollments:)
      members = @report.
        hopwa_caper_enrollments.
        head_of_household.
        where(report_household_id: enrollments.select(:report_household_id)).as_report_members
      sheet.append_row(label: label) do |row|
        row.append_cell_members(members: members)
      end
    end

    def add_sevices_fa_amount_row(sheet, label:, services:)
      sum = services.map(&:fa_amount).compact.sum
      sheet.append_row(label: label) do |row|
        row.append_cell_members(members: services.as_report_members, value: sum)
      end
    end

    def income_levels_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::IncomeBenefitLevelFilter.all
      filters.each do |filter|
        add_household_enrollments_row(sheet, label: "What is the number of #{filter.label}?", enrollments: filter.apply(relevant_enrollments))
      end
    end

    def income_sources_sheet(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::IncomeBenefitSourceFilter.all
      sheet.append_row(label: 'How many households accessed or maintained access to the following sources of income in the past year?')
      filters.each do |filter|
        add_household_enrollments_row(sheet, label: filter.label, enrollments: filter.apply(relevant_enrollments))
      end
    end

    def medical_insurance(sheet)
      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::MedicalInsuranceFilter.all
      sheet.append_row(label: 'How many households accessed or maintained access to the following sources of medical insurance in the past year?')
      filters.each do |filter|
        add_household_enrollments_row(sheet, label: filter.label, enrollments: filter.apply(relevant_enrollments))
      end
    end

    def housing_outcomes_sheet(sheet)
      add_household_enrollments_row(
        sheet,
        label: "How many households continued receiving this type of HOPWA assistance into the next year?",
        enrollments: relevant_enrollments.where(exit_date: nil),
      )

      filters = HopwaCaper::Generators::Fy2024::EnrollmentFilters::ExitDestinationFilter.all
      filters.each do |filter|
        add_household_enrollments_row(sheet, label: filter.label, enrollments: filter.apply(relevant_enrollments))
      end
    end
  end
end
