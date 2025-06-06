###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module InactiveClientReport::DocumentExports
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
        self.filename = "#{report.class.name} - #{Time.current.to_fs(:db)}"
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
        wb.add_worksheet(name: 'Clients') do |sheet|
          sheet.styles.add_style(sz: 24, b: true, alignment: { horizontal: :center })
          header = ['Warehouse ID']
          header += ['Last Name', 'First Name'] if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          header << 'DOB' if user.can_view_full_dob? && GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
          header += [
            'Age',
            'Last Seen',
            'Ongoing Enrollments',
            'Days Homeless in the Last 3 Years',
            'Days Since Most-Recent Contact',
            'Most-Recent Entry Date',
            'Most-Recent Current Living Situation',
            'Most-Recent Bed Night',
            'Most-Recent CE Assessment',
            'Most-Recent CE Assessor',
          ]

          sheet.add_row(header, style: header_style)
          report.clients.find_each do |client|
            projects = client.last_intentional_contacts(user, include_confidential_names: false, include_dates: true).select(&:present?)
            row = [client.id]
            row += [client.last_name, client.first_name] if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
            row << client.dob if user.can_view_full_dob? && GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
            row << GrdaWarehouse::Hud::Client.age(date: Date.current, dob: client.dob)
            row << projects.join('; ')
            row << client.service_history_entry_ongoing.map { |en| en&.project&.name(user, include_project_type: true) }.compact.join('; ')
            row << client.processed_service_history&.days_homeless_last_three_years
            row << report.days_since_most_recent_contact(client)
            row << report.max_entry_date(client)
            row << report.most_recent_cls(client)
            row << report.most_recent_bed_night(client)
            row << report.most_recent_ce_assessment(client)&.dig(:assessment_date)
            row << report.most_recent_ce_assessment(client)&.dig(:assessor)

            sheet.add_row(row)
          end
        end
      end
    end
    protected def report_class
      InactiveClientReport::Report
    end

    private def controller_class
      InactiveClientReport::WarehouseReports::ReportsController
    end
  end
end
