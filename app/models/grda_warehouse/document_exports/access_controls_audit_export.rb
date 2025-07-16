###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::DocumentExports
  class AccessControlsAuditExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include AccessControlAuditData

    def authorized?
      user.can_audit_users?
    end

    def regenerate?
      true
    end

    def perform
      with_status_progression do
        self.filename = "access-controls-audit-history-#{Date.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      # Generate CSV data using existing logic
      audit_history = []
      histories = build_histories(user)
      histories.each_with_index do |history, index|
        csv_data = generate_audit_csv(history.version_array, history, include_headers: index == 0)
        audit_history << csv_data
      end

      # Convert CSV to Excel
      csv_content = audit_history.join

      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: 'Access Controls Audit History') do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })

          # Parse CSV and add to Excel
          CSV.parse(csv_content, headers: true) do |row|
            if row.header_row?
              # Add headers with styling
              sheet.add_row(row.fields, style: title)
            else
              # Add data rows
              sheet.add_row(row.fields)
            end
          end
        end
      end
    end
  end
end
