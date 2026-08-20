###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserDirectoryReport::DocumentExports
  class InactiveWarehouseUserDirectoryExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    include UserDirectoryReport::DirectoryUsers

    def authorized?
      user.can_view_any_reports?
    end

    def perform
      with_status_progression do
        self.filename = "Inactive Warehouse User Directory Report - #{Time.current.to_fs(:db)}.xlsx"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: 'Inactive Warehouse Users'[0, 30]) do |sheet|
          title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
          sheet.add_row(
            [
              'Name',
              'Email',
              'Phone',
              'Agency',
              'Roles',
              'Status',
              'Last Login',
            ], style: title
          )
          directory_users(User, active: false).each do |user|
            sheet.add_row(
              [
                user.name,
                user.email,
                user.phone_for_directory,
                user.agency_name,
                user.unique_role_names&.sort&.join('; '),
                'Inactive',
                user.last_sign_in_at,
              ],
            )
          end
        end
      end
    end
  end
end
