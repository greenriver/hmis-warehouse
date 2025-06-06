###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ZipCodeReport::DocumentExports
  class ReportExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(filter)
    end

    def perform
      with_status_progression do
        self.filename = "Zip Code Report - #{Time.current.to_fs(:db)}"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb_styles = wb.styles
        header_style = wb_styles.add_style({ sz: 14 })
        wb_styles.add_style(
          {
            border: { style: :thin, color: 'FFFFFF', edges: [:bottom, :top] },
          },
        )
        wb.add_worksheet(name: 'Zip Codes') do |sheet|
          sheet.styles.add_style(sz: 24, b: true, alignment: { horizontal: :center })
          row = [
            'Zip Codes',
            'Clients',
            'Households',
          ]
          sheet.add_row(row, style: header_style)
          report.zip_code_data.map do |k, _|
            [
              k.to_s,
              report.clients_count(k),
              report.households_count(k),
            ]
          end.sort_by(&:first).each do |r|
            sheet.add_row(r, types: [:string, nil, nil])
          end
        end
      end
    end

    protected def report_class
      ZipCodeReport::Report
    end

    private def controller_class
      ZipCodeReport::WarehouseReports::ReportsController
    end
  end
end
