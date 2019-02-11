module WarehouseReports
  class HmisExportsController < ApplicationController
    include WarehouseReportAuthorization
    before_action :require_can_export_hmis_data!
    before_action :set_export, only: [:show, :destroy]
    before_action :set_jobs, only: [:index, :running, :create]
    before_action :set_exports, only: [:index, :running, :create]

    def index
      @filter = ::Filters::HmisExport.new(user_id: current_user.id)
      @all_project_names = GrdaWarehouse::Hud::Project.order(ProjectName: :asc).pluck(:ProjectName)
    end

    def running

    end

    def set_jobs
      @job_reports = Delayed::Job.where(queue: :hmis_six_one_one_export).order(run_at: :desc).map do |job|
        parameters = YAML.load(job.handler).job_data['arguments'].first
        parameters.delete('_aj_symbol_keys')
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
        if frequency > 0
          recurring_export = GrdaWarehouse::RecurringHmisExport.create(recurrence_params.merge(user_id: current_user.id))
          @filter.recurring_hmis_export_id = recurring_export.id
        end
        WarehouseReports::HmisSixOneOneExportJob.perform_later(@filter.options_for_hmis_export(:six_one_one).as_json, report_url: warehouse_reports_hmis_exports_url)
        redirect_to warehouse_reports_hmis_exports_path
      else
        render :index
      end
    end

    def destroy
      @export.destroy
      respond_with @export, location: warehouse_reports_hmis_exports_path
    end

    def show
      # send_data GrdaWarehouse::Hud::Geography.to_csv(scope: @sites), filename: "site-#{Time.now}.csv"
      send_data @export.content, filename: "HMIS_export_#{Time.now.to_s.gsub(',', '')}.zip", type: @export.content_type, disposition: 'attachment'
    end

    def cancel
      report_id = params[:id].to_i
      recurring_export_source.find_by(hmis_export_id: report_id).destroy
      redirect_to :index
    end

    def recurring?(report)
      recurring_export_source.where(hmis_export_id: report.id).exists?
    end
    helper_method :recurring?

    def set_export
      @export = export_source.find(params[:id].to_i)
    end

    def export_source
      GrdaWarehouse::HmisExport
    end

    def recurring_export_source
      GrdaWarehouse::RecurringHmisExport
    end

    def export_scope
      if current_user.can_edit_anything_super_user?
        export_source.all
      else
        export_source.where(user_id: current_user.id)
      end
    end

    def report_params
      params.require(:filter).permit(
        :start_date,
        :end_date,
        :hash_status,
        :period_type,
        :include_deleted,
        :faked_pii,
        project_ids: [],
        project_group_ids: [],
        organization_ids: [],
        data_source_ids: []
      )
    end

    def recurrence_params
      params.require(:filter).permit(
          :start_date,
          :end_date,
          :hash_status,
          :period_type,
          :include_deleted,
          :faked_pii,
          :every_n_days,
          :reporting_range,
          :reporting_range_days,
          project_ids: [],
          project_group_ids: [],
          organization_ids: [],
          data_source_ids: []
      )
    end

    def flash_interpolation_options
      { resource_name: 'Export' }
    end

  end
end
