###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserDirectoryReport::DocumentExports
  class CasUserDirectoryExcelExport < ::GrdaWarehouse::DocumentExport
    include ApplicationHelper
    def authorized?
      user.can_view_any_reports?
    end

    private def _users(user_model)
      if params[:q].present?
        users = user_model.in_directory.
          text_search(params[:q]).
          order(:last_name, :first_name)
      else
        users = user_model.in_directory.
          order(:last_name, :first_name)
      end
      return users
    end

    def perform
      with_status_progression do
        self.filename = "CAS User Directory Report - #{Time.current.to_fs(:db)}"
        self.file_data = excel_package.to_stream.read
        self.mime_type = EXCEL_MIME_TYPE
      end
    end

    private def excel_package
      Axlsx::Package.new do |package|
        wb = package.workbook
        wb.add_worksheet(name: 'CAS Users'[0, 30]) do |sheet|
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
              'Count of Active Matches',
              'Count of Closed Matches',
            ], style: title
          )
          _users(CasAccess::User).each do |user|
            sheet.add_row(
              [
                user.name,
                user.email,
                user.phone_for_directory,
                user.agency_name,
                user.unique_role_names&.sort&.join('; '),
                user.active ? 'Active' : 'Inactive',
                user.last_sign_in_at,
                user.contact&.client_opportunity_matches&.merge(CasAccess::ClientOpportunityMatch.active)&.count,
                user.contact&.client_opportunity_matches&.merge(CasAccess::ClientOpportunityMatch.closed)&.count,
              ],
            )
          end
        end
      end
    end

    private def controller_class
      UserDirectoryReport::WarehouseReports::UsersController
    end
  end
end
