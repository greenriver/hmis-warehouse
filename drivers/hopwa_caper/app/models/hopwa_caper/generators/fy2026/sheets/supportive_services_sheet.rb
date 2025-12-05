# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper::Generators::Fy2026::Sheets
  class SupportiveServicesSheet < Base
    QUESTION_NUMBER = 'Q6: Supportive Services'
    QUESTION_NUMBERS = ['Q6'].freeze
    SHEET_TITLE = 'Complete for all households served with HOPWA funded Supportive Services by your organization in the reporting year.'

    CONTENTS = [
      { method: :supportive_services_section, label: 'Households and Expenditures for Supportive Service Types' },
      { method: :deduplication_section, label: 'Deduplication of Supportive Services' },
    ].freeze

    protected

    def run_question!
      question_number = self.class::QUESTION_NUMBER
      tables = self.class::QUESTION_NUMBERS
      contents = self.class::CONTENTS
      @report.start(question_number, tables)
      raise unless tables.one?

      question_sheet(question: tables.first) do |sheet|
        add_sheet_header(sheet, title: self.class::SHEET_TITLE)
        contents.each do |opts|
          opts => { method:, label: }
          sheet.append_row(label: label) do |row|
            if opts == contents.first # firs row has headers
              row.append_cell_value(value: 'Number of Households')
              row.append_cell_value(value: 'Expenditures')
            end
          end
          send(method, sheet)
        end
      end

      @report.complete(question_number)
    end

    def add_sheet_header(sheet, title:)
      sheet.add_header(col: 'A', label: title)
      sheet.add_header(col: 'B', label: '')
      sheet.add_header(col: 'C', label: '')

      sheet.append_row(label: 'Questions') do |row|
        row.append_cell_value(value: 'This Report')
        row.append_cell_value(value: 'This Report')
      end
    end

    def supportive_services_section(sheet)
      sheet.append_row(label: 'What were the expenditures and number of households for each of the following types of supportive services in the program year?')

      service_type_filters.all.each do |filter|
        scope = filter.apply(relevant_services)
        append_supportive_service_row(sheet, label: filter.label, services: scope)
      end

      sheet.append_row(label: 'What were the other type(s) of supportive services provided? (150 characters).')
    end

    def deduplication_section(sheet)
      sheet.append_row(label: 'How many households received more than one type of Supportive Services?') do |row|
        row.append_cell_members(members: service_members(multi_service_households))
        row.append_cell_value(value: nil)
      end

      sheet.append_row(label: '')

      sheet.append_row(label: 'Deduplicated Supportive Services Household Total (based on amounts reported in Rows 5-21 above)') do |row|
        row.append_cell_members(members: service_members(all_supportive_service_households))
        row.append_cell_value(value: nil)
      end
    end

    private

    def append_supportive_service_row(sheet, label:, services:)
      sheet.append_row(label: label) do |row|
        row.append_cell_members(members: service_members(services))
        row.append_cell_value(value: nil)
      end
    end

    def service_members(services)
      return [] if services.none?

      HopwaCaper::Enrollment.head_of_household.
        where(report_instance_id: @report.id, report_household_id: services.select(:report_household_id)).
        latest_by_distinct_hoh_client_id.
        as_report_members
    end

    def multi_service_households
      relevant_services.
        where(type_provided: service_type_filters.supportive_service_codes).
        group(:report_household_id).
        having('COUNT(DISTINCT type_provided) > 1')
    end

    def all_supportive_service_households
      relevant_services.where(type_provided: service_type_filters.supportive_service_codes)
    end

    def relevant_services
      @relevant_services ||= begin
        record_filter = HopwaCaper::Generators::Fy2026::ServiceFilters::RecordTypeFilter.hopwa_service
        record_filter.apply(@report.hopwa_caper_services).
          where(date_provided: @report.start_date..@report.end_date)
      end
    end

    def service_type_filters
      HopwaCaper::Generators::Fy2026::ServiceFilters::SupportiveServiceTypeFilter
    end
  end
end
