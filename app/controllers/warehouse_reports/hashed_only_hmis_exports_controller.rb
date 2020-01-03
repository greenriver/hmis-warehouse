###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class HashedOnlyHmisExportsController < HmisExportsController
    include WarehouseReportAuthorization
    def create
      @filter = ::Filters::HmisExport.new(report_params.merge(user_id: current_user.id, hash_status: '4'))
      if @filter.valid?
        WarehouseReports::HmisSixOneOneExportJob.perform_later(@filter.options_for_hmis_export(:six_one_one).as_json, report_url: warehouse_reports_hashed_only_hmis_exports_url)
        redirect_to warehouse_reports_hashed_only_hmis_exports_path
      else
        render :index
      end
    end

    def destroy
      @export.destroy
      respond_with @export, location: warehouse_reports_hashed_only_hmis_exports_path
    end

    def export_scope
      super().where(hash_status: 4)
    end

    def report_params
      params.require(:filter).permit(
        :start_date,
        :end_date,
        :period_type,
        :include_deleted,
        project_ids: [],
        project_group_ids: [],
        organization_ids: [],
        data_source_ids: [],
      )
    end
  end
end
