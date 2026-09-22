###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module UserDirectoryReport::WarehouseReports
  class UsersController < ApplicationController
    include WarehouseReportAuthorization
    include UserDirectoryReport::DirectoryUsers

    helper_method :nav_link_classes
    helper_method :cas_available?
    helper_method :warehouse_user_source?
    helper_method :hmis_data_sources
    helper_method :hmis_data_sources_for
    helper_method :hmis_data_source_linkable?

    # Both actions are the same report, and there is no :index for the concern's default
    # derivation to use; the seeded definition is registered under the warehouse action's
    # path (see GrdaWarehouse::WarehouseReports::ReportDefinition).
    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.
        where(url: 'user_directory_report/warehouse_reports/users/warehouse')
    end

    def readonly?
      true
    end

    def warehouse
      @users = directory_users(User)
      @user_source = 'warehouse'
      @excel_export = UserDirectoryReport::DocumentExports::WarehouseUserDirectoryExcelExport.new
      respond_to do |format|
        format.html { @pagy, @users = pagy(@users) }
        format.xlsx do
          filename = "Warehouse User Directory Report - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def inactive
      @users = directory_users(User, active: false)
      @user_source = 'inactive'
      @excel_export = UserDirectoryReport::DocumentExports::WarehouseUserDirectoryExcelExport.new
      respond_to do |format|
        format.html { @pagy, @users = pagy(@users) }
        format.xlsx do
          filename = "Warehouse User Directory Report - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def cas
      if cas_available?
        @users = directory_users(CasAccess::User)
      else
        @users = []
      end
      @user_source = 'cas'
      @excel_export = UserDirectoryReport::DocumentExports::CasUserDirectoryExcelExport.new
      respond_to do |format|
        format.html { @pagy, @users = pagy(@users) }
        format.xlsx do
          filename = "CAS User Directory Report - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def nav_link_classes(link_type, user_source)
      class_list = ['nav-link']
      class_list.append('active') if link_type == user_source
      class_list.join(' ')
    end

    def warehouse_user_source?
      @user_source.in?(['warehouse', 'inactive'])
    end

    def cas_available?
      CasBase.db_exists? && CasAccess::User.take.respond_to?('exclude_from_directory')
    end

    def hmis_data_source_linkable?(hmis_ds)
      return false unless current_user.can_view_imports_projects_or_organizations?

      @viewable_hmis_data_source_ids ||= GrdaWarehouse::DataSource.hmis.viewable_by(current_user).pluck(:id).to_set
      @viewable_hmis_data_source_ids.include?(hmis_ds.id)
    end
  end
end
