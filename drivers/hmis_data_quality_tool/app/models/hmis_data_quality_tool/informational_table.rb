###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class InformationalTable

    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper

    ROWS_DATA = [
      {
        title: "Most-Recent Enrollment Chronic at Entry",
        description: "Count of clients for whom their most recent enrollment was chronic at entry.",
        value_meth: :client_ch_most_recent
      },
      {
        title: "Any Enrollment Chronic at Entry",
        description: "Count of clients who had at least one enrollment during the reporting period that was chronic at entry.",
        value_meth: :client_ch_any
      },
      {
        title: "Total Enrollments Chronic at Entry",
        description: "Count of enrollments in the universe that were chronic at entry.",
        value_meth: :enrollment_any_ch
      },
      {
        title: "Average Time Homeless Before Entry",
        description: "Average number of days between approximate start of episode (3.917.3) and entry date for clients who have an approximate start.",
        value_meth: :average_days_before_entry
      },
      {
        title: "Percent of Exits to Temporary Destinations",
        description: "The percentage of everyone with an exit date that was to a temporary destination.",
        value_meth: :destination_temporary,
        xlsx_styles: {format_code: '0%'}
      },
      {
        title: "Percent of Exits to Other Destinations",
        description: "The percentage of everyone with an exit date that was to a destination in the category other.",
        value_meth: :destination_other,
        xlsx_styles: {format_code: '0%'}
      }
    ]

    def initialize(report, template_format)
      @report = report
      @format = template_format
    end

    def rows
      ROWS_DATA.map do |row|
        key = row[:value_meth]
        row.merge({value: send(key), value_path: value_path(key)})
      end
    end

    private

    def client_ch_most_recent
      number_with_delimiter(@report.items_for(:client_ch_most_recent).select(:client_id).distinct.count)
    end

    def client_ch_any
      number_with_delimiter(@report.items_for(:client_ch_any).select(:client_id).distinct.count)
    end

    def enrollment_any_ch
      number_with_delimiter(@report.items_for(:enrollment_any_ch).select(:enrollment_id).distinct.count)
    end

    def average_days_before_entry
      number_with_delimiter(@report.average_days_before_entry)
    end

    def destination_temporary
      v = @report.destination_percent('destination_temporary')
      @format == :xlsx ? v/100.0 : "#{number_with_delimiter(v)}%"
    end

    def destination_other
      v = @report.destination_percent('destination_other')
      @format == :xlsx ? v/100.0 : "#{number_with_delimiter(v)}%"
    end

    def value_path(key)
      items_hmis_data_quality_tool_warehouse_reports_report_path(@report, key: key)
    end

  end
end