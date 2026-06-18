###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::DocumentExports
  class HmisAccessControlsAuditExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include HmisAccessControlAuditData

    def authorized?
      HmisEnforcement.hmis_admin_visible?(user)
    end

    def regenerate?
      true
    end

    def perform
      with_status_progression do
        self.filename = "hmis-access-controls-audit-history-#{Date.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: 'HMIS Access Controls Audit History') do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })

          histories = build_histories
          histories.each_with_index do |history, header_index|
            csv_data = generate_audit_csv(history.version_array, history, include_headers: header_index == 0)
            csv_data.lines.each_with_index do |line, line_index|
              row = CSV.parse_line(line)
              if header_index == 0 && line_index == 0
                sheet.add_row(row, style: title)
              else
                sheet.add_row(row)
              end
            end
          end
        end
      end
    end
  end
end
