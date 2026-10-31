###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::WarehouseReports::DocumentExports
  class ActiveClientReportExcelExport < ActiveClientReportExport
    def authorized?
      super && user.can_view_clients?
    end

    def perform
      with_status_progression do
        self.file_data = controller_class.render(
          template: 'warehouse_reports/client_details/actives/index',
          formats: [:xlsx],
          assigns: view_assigns,
          locals: { current_user: user },
        )
        self.filename = "Active Clients #{Time.current.to_fs(:db)}.xlsx"
        self.mime_type = EXCEL_MIME_TYPE
      end
    end
  end
end
