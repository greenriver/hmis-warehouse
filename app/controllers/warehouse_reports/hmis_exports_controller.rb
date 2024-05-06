###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class HmisExportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_export_hmis_data!
    before_action :set_export, only: [:show, :destroy, :cancel, :edit, :update]
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
        parameters = YAML.unsafe_load(job.handler).job_data['arguments'].first
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
        preload(:recurring_hmis_export).
        limit(50)
    end

    def create
      options = report_params.merge(user_id: current_user.id)
      # options that are specific to recurring exports should be stored on the recurring export, not the filter
      options = options.except(*recurrence_param_keys)
      @filter = ::Filters::HmisExport.new(options)
      if @filter.valid?
        frequency = recurrence_params[:every_n_days].to_i || 0
        if frequency.positive?
          recurring_export = GrdaWarehouse::RecurringHmisExport.create(recurrence_params.merge(user_id: current_user.id, options: @filter.to_h))
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
      send_data @export.content, filename: "HMIS_export_#{@export.created_at.to_s.delete(',')}.zip", type: @export.content_type, disposition: 'attachment'
    end

    def edit
      @recurrence = @export.recurring_hmis_export
    end

    def update
      @export.recurring_hmis_export.update(recurrence_params.merge(user_id: current_user.id))
      flash[:notice] = 'Recurrence options updated'
      redirect_to warehouse_reports_hmis_exports_path
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
      export_source.clean_params(
        params.require(:filter).permit(
          :version,
          :start_date,
          :end_date,
          :hash_status,
          :period_type,
          :include_deleted,
          :directive,
          :faked_pii,
          :confidential,
          :reporting_range,
          :reporting_range_days,
          :reporting_range,
          :reporting_range_days,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: [],
          coc_codes: [],
        ),
      )
    end

    def recurrence_params
      export_source.clean_params(params.require(:filter).permit(*recurrence_param_keys))
    end

    private def recurrence_param_keys
      [
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
      ]
    end

    def flash_interpolation_options
      { resource_name: 'Export' }
    end
  end
end
