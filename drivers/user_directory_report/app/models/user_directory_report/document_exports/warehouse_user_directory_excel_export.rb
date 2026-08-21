###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserDirectoryReport::DocumentExports
  class WarehouseUserDirectoryExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include UserDirectoryReport::DirectoryUsers

    HEADERS = [
      'Name',
      'Email',
      'Phone',
      'Agency',
      'Roles',
      'Status',
      'Last Login',
    ].freeze

    def authorized?
      user.can_view_any_reports?
    end

    def perform
      with_status_progression do
        self.filename = "Warehouse User Directory Report - #{Time.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        add_sheet(wb, 'Active Warehouse Users', directory_users(User), 'Active')
        add_sheet(wb, 'Inactive Warehouse Users', directory_users(User, active: false), 'Inactive')
      end
    end

    private def add_sheet(workbook, name, users, status)
      workbook.add_worksheet(name: name[0, 30]) do |sheet|
        title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
        sheet.add_row(HEADERS, style: title)
        users.each do |user|
          sheet.add_row(
            [
              user.name,
              user.email,
              user.phone_for_directory,
              user.agency_name,
              user.unique_role_names&.sort&.join('; '),
              status,
              user.last_sign_in_at,
            ],
          )
        end
      end
    end
  end
end
