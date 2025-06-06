###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module StartDateDq::DocumentExports
  class StartDateDqExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports? && report_class.viewable_by(user)
    end

    protected def report
      @report ||= report_class.new(user.id, filter)
    end

    def perform
      with_status_progression do
        self.filename = "#{report.title} Data Quality Report #{DateTime.current.to_fs(:db)}"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: report.title[0, 30]) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(["Enrollments between #{filter.start} and #{filter.end}"])
          sheet.add_row(
            [
              'Warehouse Client ID',
            ] + report.column_names,
            style: title,
          )
          report.data.each do |row|
            client = row.client
            sheet.add_row([
              client.id,
            ] + report.column_values(row, user).values)
          end
        end
      end
    end

    protected def report_class
      StartDateDq::Report
    end

    private def controller_class
      StartDateDq::WarehouseReports::ReportsController
    end
  end
end
