###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module WarehouseReports
  class HashedOnlyHmisExportsController < HmisExportsController
    include WarehouseReportAuthorization
    def create
      @filter = ::Filters::HmisExport.new(report_params.merge(user_id: current_user.id, hash_status: '4'))
      if @filter.valid?
        @filter.schedule_job(report_url: warehouse_reports_hashed_only_hmis_exports_url)

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
      export_source.clean_params(
        params.require(:filter).permit(
          :start_date,
          :end_date,
          :period_type,
          :include_deleted,
          :version,
          :enforce_project_date_scope,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
          coc_codes: [],
        ),
      )
    end

    def path_for_report(report)
      warehouse_reports_hashed_only_hmis_export_path(report)
    end
    helper_method :path_for_report

    def path_for_new
      warehouse_reports_hashed_only_hmis_exports_path
    end
    helper_method :path_for_new
  end
end
