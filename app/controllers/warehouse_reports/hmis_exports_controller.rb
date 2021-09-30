###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class HmisExportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_export_hmis_data!
    before_action :set_export, only: [:show, :destroy, :cancel]
    before_action :set_jobs, only: [:index, :running, :create]
    before_action :set_exports, only: [:index, :running, :create]

    def index
      @filter = ::Filters::HmisExport.new(user_id: current_user.id)
      @all_project_names = GrdaWarehouse::Hud::Project.order(ProjectName: :asc).pluck(:ProjectName)
    end

    def running
    end

    def set_jobs
      @job_reports = Delayed::Job.jobs_for_class(::Filters::HmisExport.job_classes).order(run_at: :desc).map do |job|
        parameters = YAML.load(job.handler).job_data['arguments'].first # rubocop:disable Security/YAMLLoad
        parameters.delete('_aj_symbol_keys')
        parameters.delete('_aj_globalid')
        parameters['project_ids'] = parameters.delete('projects')
        report = GrdaWarehouse::HmisExport.new(parameters)

        [job.run_at, report]
      end
    end

    def set_exports
      @exports = export_scope.ordered.
        for_list.
        limit(50)
    end

    def create
      @filter = ::Filters::HmisExport.new(report_params.merge(user_id: current_user.id))
      if @filter.valid?
        frequency = recurrence_params[:every_n_days].to_i || 0
        if frequency.positive?
          recurring_export = GrdaWarehouse::RecurringHmisExport.create(recurrence_params.merge(user_id: current_user.id))
          @filter.recurring_hmis_export_id = recurring_export.id
        end
        @filter.adjust_reporting_period
        if recurring_export&.s3_present? && ! recurring_export.s3_valid?
          flash[:error] = 'Invalid S3 Configuration'
          render :index
        else
          @filter.schedule_job(report_url: warehouse_reports_hmis_exports_url)

          redirect_to warehouse_reports_hmis_exports_path
        end
      else
        render :index
      end
    end

    def destroy
      @export.destroy
      respond_with @export, location: warehouse_reports_hmis_exports_path
    end

    def show
      # send_data GrdaWarehouse::Hud::Geography.to_csv(scope: @sites), filename: "site-#{Time.current.to_s(:number)}.csv"
      send_data @export.content, filename: "HMIS_export_#{@export.created_at.to_s.delete(',')}.zip", type: @export.content_type, disposition: 'attachment'
    end

    def cancel
      @export.recurring_hmis_export.destroy if can_cancel? @export
      redirect_to warehouse_reports_hmis_exports_path
    end

    def can_cancel?(report)
      report.user_id == current_user.id || can_view_all_reports?
    end
    helper_method :can_cancel?

    def set_export
      @export = export_source.find(params[:id].to_i)
    end

    def export_source
      ::GrdaWarehouse::HmisExport
    end

    def recurring_export_source
      ::GrdaWarehouse::RecurringHmisExport
    end

    def recurring_export_link_source
      ::GrdaWarehouse::RecurringHmisExportLink
    end

    def export_scope
      if can_view_all_reports?
        export_source.all
      else
        export_source.where(user_id: current_user.id)
      end
    end

    def report_params
      params.require(:filter).permit(
        :version,
        :start_date,
        :end_date,
        :hash_status,
        :period_type,
        :include_deleted,
        :directive,
        :faked_pii,
        :reporting_range,
        :reporting_range_days,
        :reporting_range,
        :reporting_range_days,
        project_ids: [],
        project_group_ids: [],
        organization_ids: [],
        data_source_ids: [],
      )
    end

    def recurrence_params
      params.require(:filter).permit(
        :version,
        :start_date,
        :end_date,
        :hash_status,
        :period_type,
        :include_deleted,
        :directive,
        :faked_pii,
        :every_n_days,
        :reporting_range,
        :reporting_range_days,
        :s3_access_key_id,
        :s3_secret_access_key,
        :s3_region,
        :s3_bucket,
        :s3_prefix,
        :zip_password,
        :encryption_type,
        project_ids: [],
        project_group_ids: [],
        organization_ids: [],
        data_source_ids: [],
      )
    end

    def flash_interpolation_options
      { resource_name: 'Export' }
    end
  end
end
