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

    def authorized?
      user.can_view_any_reports?
    end

    # Column title => how to fill that cell for one user, in spreadsheet column order: a
    # symbol to read the attribute, or a lambda for anything computed. The header and every
    # row are both derived from this, so a column can be added, reordered, or dropped in
    # one place. 'Status' is fixed per sheet.
    private def columns_for(status)
      columns = {
        'Name' => :name,
        'Email' => :email,
        'Phone' => :phone_for_directory,
        'Agency' => :agency_name,
        'Roles' => ->(directory_user) { directory_user.unique_role_names&.sort&.join('; ') },
        'Status' => ->(_directory_user) { status },
        'HMIS Access' => ->(directory_user) { hmis_cell_for(directory_user) },
        'Last Login' => :last_sign_in_at,
      }
      columns.delete('HMIS Access') if hmis_data_sources.none?
      columns
    end

    # Every HMIS installation on this deployment; empty when HMIS is off, which is what
    # drops the column from the spreadsheet.
    private def hmis_data_sources
      @hmis_data_sources ||= HmisEnforcement.hmis_enabled? ? GrdaWarehouse::DataSource.hmis.to_a : []
    end

    private def hmis_access_by_user_id
      return @hmis_access_by_user_id if defined?(@hmis_access_by_user_id)

      @hmis_access_by_user_id = hmis_data_sources.any? ? Hmis::User.accessible_hmis_data_source_ids_by_user_id : {}
    end

    # Yes for a single HMIS installation, standing in for the check the screen shows;
    # the name of each data source when there are several, matching its links.
    private def hmis_cell_for(user)
      accessible_ids = hmis_access_by_user_id.fetch(user.id, [])
      accessible = hmis_data_sources.select { |hmis_ds| accessible_ids.include?(hmis_ds.id) }
      return '' if accessible.none?
      return 'Yes' if hmis_data_sources.one?

      accessible.map(&:name).join('; ')
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
      columns = columns_for(status)
      workbook.add_worksheet(name: name[0, 30]) do |sheet|
        title = sheet.styles.add_style(sz: 12, b: true, alignment: { horizontal: :center })
        sheet.add_row(columns.keys, style: title)
        users.each do |directory_user|
          sheet.add_row(columns.each_value.map { |cell| cell.to_proc.call(directory_user) })
        end
      end
    end
  end
end
