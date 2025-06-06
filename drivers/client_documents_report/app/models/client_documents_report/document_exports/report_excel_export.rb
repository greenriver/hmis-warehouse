###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ClientDocumentsReport::DocumentExports
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
        self.filename = "Client Documents - #{Time.current.to_fs(:db)}"
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
        wb.add_worksheet(name: 'Documents') do |sheet|
          sheet.styles.add_style(sz: 24, b: true, alignment: { horizontal: :center })
          row = ['Warehouse ID']
          row += ['Last Name', 'First Name'] if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)

          row += [
            'Required Documents',
            'Optional Documents',
            'All Documents',
          ]
          [:required, :optional].each do |type|
            report.groups_for_type(type).each do |group, tags|
              row << "#{group} (#{ActionController::Base.helpers.pluralize(tags.count, 'tags')} - #{type})"
              tags.each do |tag|
                row << tag
              end
            end
          end
          row += report.additional_client_data_headers
          sheet.add_row(row, style: header_style)
          # find_each doesn't support ordering the SQL, so we'll pluck the ids and loop over slices
          report.clients.order(:last_name, :first_name).pluck(:id).each_slice(1_000) do |slice|
            report.clients.where(id: slice).order(:last_name, :first_name).each do |client|
              row = [client.id]
              row += [client.last_name, client.first_name] if GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
              row << report.required_documents(client).count
              row << report.optional_documents(client).count
              row << report.overall_documents(client).count
              types = [:required, :optional]
              types.each do |type|
                report.groups_for_type(type).each do |group, tags|
                  row << report.date_for_group(group, client, type: type)
                  tags.each do |tag|
                    row << report.date_for_tag(tag, client, type: type)
                  end
                end
              end
              client_details = report.additional_client_data(client)
              report.additional_client_data_headers.each do |h|
                row << client_details[h]
              end
              sheet.add_row(row)
            end
          end
        end
      end
    end

    protected def report_class
      ClientDocumentsReport::Report
    end

    private def controller_class
      ClientDocumentsReport::WarehouseReports::ReportsController
    end
  end
end
