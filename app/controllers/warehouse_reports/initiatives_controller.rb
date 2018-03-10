module WarehouseReports
  class InitiativesController < ApplicationController
    include PjaxModalController
    include WarehouseReportAuthorization
    # Authorize by either access to report OR access by token
    skip_before_action :authenticate_user!
    skip_before_action :require_can_view_any_reports!
    before_action :set_report, only: [:show, :destroy]
    before_action :set_jobs, only: [:index, :running, :create]
    before_action :set_reports, only: [:index, :running, :create]

    def index
      @filter = ::Filters::Initiative.new()
    end

    def running

    end

    def set_jobs
      @job_reports = Delayed::Job.where(queue: :initiative_reports).order(run_at: :desc).map do |job|
        parameters = YAML.load(job.handler).job_data['arguments'].first
        parameters.delete('_aj_symbol_keys')
        parameters['project_ids'] = parameters.delete('projects')
        report = WarehouseReports::InitiativeReportJob.new(parameters)
        [job.run_at, report]
      end
    end

    def set_reports
      @reports = report_source.ordered.
        for_list.
        limit(50)
    end

    def create
      @filter = ::Filters::Initiative.new(report_params)
      if @filter.valid?
        WarehouseReports::InitiativeReportJob.perform_later(@filter.options_for_initiative().as_json)
        redirect_to warehouse_reports_initiatives_path
      else
        render :index
      end
    end

    def destroy
      
    end

    def show
      @parameters = OpenStruct.new(@report.parameters.with_indifferent_access)
      @data = OpenStruct.new(@report.data.with_indifferent_access)
      # @chart_data_template = {mean: {report:[], comparison:[]}, median: {report:[], comparison: []}, types: [], values: []}
    end

    def los_charts
      [
        {
          title: 'Changes in Length of Stay in Days by Project Type',
          legend_id: 'd3-losobt__legend',
          mean_chart_id: 'd3-losobt__mean',
          median_chart_id: 'd3-losobt__median',
          collapse_id: 'losobt__collapse',
          chart_data: los_by_project_type_chart_data
        },
        {
          title: 'Changes in Length of Stay in Days by Project',
          legend_id: 'd3-losobp__legend',
          mean_chart_id: 'd3-losobp__mean',
          median_chart_id: 'd3-losobp__median',
          collapse_id: 'losobp__collapse',
          chart_data: los_by_project_chart_data
        }
      ]
    end
    helper_method :los_charts

    def los_chart_data_template
      {mean: {report:[], comparison:[]}, median: {report:[], comparison: []}, types: [], values: []}
    end

    # los = length of stay
    def los_by_project_type_chart_data()
      report_data = (@data[:all_length_of_stay_breakdowns_by_project_type] || {})
      comparison_data = (@data[:all_comparison_length_of_stay_breakdowns_by_project_type]||{})
      chart_data = los_chart_data_template
      all_keys = ((report_data.keys + comparison_data.keys) || []).uniq
      all_keys.each do |k|
        type = ::HUD.project_type_brief(k.to_i)
        [report_data, comparison_data].each_with_index do |data, index|
          values = data[k] || [0]
          mean = (values.sum.to_f/values.length).round rescue 0
          median = median(values)
          key = index == 0 ? :report : :comparison
          chart_data[:values].push(mean)
          chart_data[:values].push(median)
          chart_data[:mean][key].push([type, mean])
          chart_data[:median][key].push([type, median])
        end
      end
      chart_data[:types] = all_keys.map{|k| ::HUD.project_type_brief(k.to_i)}
      chart_data
    end
    helper_method :los_by_project_type_chart_data

    def los_by_project_chart_data
      report_data = (@data[:all_length_of_stay_breakdowns_by_project] || {})
      comparison_data = (@data[:all_comparison_length_of_stay_breakdowns_by_project] || {})
      chart_data = los_chart_data_template
      all_keys = @data.involved_projects.sort_by(&:last)
      all_keys.each do |p_id, p_name|
        [report_data, comparison_data].each_with_index do |data, index|
          values = data[p_id] || [0]
          mean = (values.sum.to_f/values.length).round rescue 0
          median = median(values)
          key = index == 0 ? :report : :comparison
          chart_data[:values].push(mean)
          chart_data[:values].push(median)
          chart_data[:mean][key].push([p_name, mean])
          chart_data[:median][key].push([p_name, median])
        end
      end
      chart_data[:types] = all_keys.map{|p_id, p_name| p_name}
      chart_data
    end
    helper_method :los_by_project_chart_data

    def cc_chart_data_template
      {counts: {report:[], comparison:[]}, types: [], values: []}
    end

    def cc_by_project_type
      report_data = @data.client_counts_by_project_type || {}
      comparison_data = @data.comparison_client_counts_by_project_type || {}
      chart_data = cc_chart_data_template
      all_keys = (report_data.keys + comparison_data.keys).uniq
      chart_data[:counts][:report] = report_data.to_a.map{|key, value| [key.split('_')[0], value]}
      chart_data[:counts][:comparison] = comparison_data.to_a.map{|key, value| [key.split('_')[0], value]}
      chart_data[:values] = report_data.values + comparison_data.values
      chart_data[:types] = (report_data.keys + comparison_data.keys).uniq.map{|key| key.split('_')[0]}
      chart_data
    end
    helper_method :cc_by_project_type

    def cc_by_project
      report_data = @data.client_counts_by_project || {}
      comparison_data = @data.comparison_client_counts_by_project || {}
      chart_data = cc_chart_data_template
      @data.involved_projects.sort_by(&:last).each do |p_id, p_name|
        key = "#{p_id}__count"
        chart_data[:counts][:report].push([p_name, (report_data[key]||0)])
        chart_data[:counts][:comparison].push([p_name, (comparison_data[key]||0)])
      end
      chart_data[:values] = report_data.values + comparison_data.values
      chart_data[:types] = @data.involved_projects.sort_by(&:last).map{|p_id, p_name| p_name}
      chart_data
    end
    helper_method :cc_by_project

    def set_report
      @report = report_source.find(params[:id].to_i)
    end

    def report_source
      GrdaWarehouse::WarehouseReports::InitiativeReport
    end

    def report_params
      params.require(:filter).permit(
        :initiative_name,
        :start, 
        :end,
        :comparison_start, 
        :comparison_end,
        :sub_population,
        project_ids: [],
        project_group_ids: [],
      )
    end

    # Override default to allow token access
    def report_visible?
      return true if access_by_token? || related_report.viewable_by(current_user).exists? 
      not_authorized!
    end

    def access_by_token?
      return false if current_user
      if params[:token].blank?
        raise ActionController::RoutingError.new('Not Found') and return
      end
      set_report
      if @report.updated_at > 3.months.ago && @report.token.present? && @report.token == params[:token]
        return true
      else
        raise ActionController::RoutingError.new('Not Found')
      end
    end

    def median array
      mid = array.size / 2
      sorted = array.sort
      array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2 
    end
    helper_method :median


  end
end