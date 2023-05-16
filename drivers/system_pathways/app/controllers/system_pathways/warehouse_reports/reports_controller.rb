###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters
    before_action :require_can_access_some_version_of_clients!, only: [:details, :items]
    before_action :set_report, only: [:show, :destroy, :details, :chart_data]
    before_action :show_filter, only: [:show, :details, :chart_data]

    def index
      @pagy, @reports = pagy(report_scope.diet.ordered)
      @report = report_class.new(user_id: current_user.id)
      @filter.default_project_type_codes = @report.default_project_type_codes
      previous_report = report_scope.where(user_id: current_user.id).last
      @filter.update(previous_report.options) if previous_report

      # Make sure the form will work
      filters
    end

    def show
      @pathways_chart = SystemPathways::PathwaysChart.new(report: @report, filter: @filter, show_filter: show_filter)
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "#{@report.title&.tr(' ', '-')}-#{Date.current.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def create
      @report = report_class.new(
        user_id: current_user.id,
      )
      @report.filter = @filter

      if @filter.valid?
        @report.save
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        # Make sure the form will work
        filters
        respond_with(@report, location: @report.index_path)
      else
        @pagy, @reports = pagy(report_scope.ordered)
        filters
        render :index
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: @report.index_path)
    end

    def chart_data
      @chart_data = @report.allowed_section(params[:chart])
      respond_to do |format|
        format.json do
          klass = case @chart_data
          when 'equity'
            SystemPathways::Equity
          when 'time'
            SystemPathways::TimeChart
          else
            raise 'unknown chart type'
          end
          data = klass.new(report: @report, filter: @filter, show_filter: show_filter).
            chart_data(params[:demographic_breakdown])
          # NOTE: data will include some metadata
          # actual chart data should be in data.data
          render json: data.to_json
        end
      end
    end

    def details
      @chart = @report.chart_model(details_params[:chart]).new(report: @report, filter: @filter, show_filter: show_filter, details_filter: details_filter)
      @node = @chart.sanitized_node(details_params[:node])
      @source = @chart.sanitized_node(details_params[:source])
      @target = @chart.sanitized_node(details_params[:target])
      @detail_options = {
        node: @node,
        source: @source,
        target: @target,
      }

      if @node.present?
        @clients = @chart.node_clients(@node).distinct
        @details_title = @node
      elsif @target.in?(@chart.destination_lookup.keys)
        # Looking at Project Type -> Destination transition
        source_project_number = HudUtility.project_type_number(@source)
        target_group = @chart.destination_lookup[@target]
        @clients = @chart.transition_clients(source_project_number, target_group).distinct
        @source_title = @source
        @details_title = "#{@source} → #{@target}"
      else
        target_project_number = HudUtility.project_type_number(@target)
        source_project_number = HudUtility.project_type_number(@source)
        @clients = @chart.transition_clients(source_project_number, target_project_number).distinct
        @source_title = if @source.present?
          @source
        else
          'Served by Homeless System'
        end
        @clients = @clients.preload(:client)
        @details_title = "#{@source_title} → #{@target}"
      end
    end

    private def filtering_show?
      return false unless params.key?(:filters)

      # If we've set any of our known options, we should show that we're filtering
      SystemPathways::Equity.known_params.map do |field|
        show_filter.send(field) == empty_filter.send(field)
      end.any?(false)
    end
    helper_method :filtering_show?

    private def filtering_details?
      return false unless params.key?(:details)

      # If we've set any of our known options, we should show that we're filtering
      SystemPathways::Equity.known_params.map do |field|
        details_filter.send(field) == empty_filter.send(field)
      end.any?(false)
    end
    helper_method :filtering_details?

    private def empty_filter
      @empty_filter ||= ::Filters::FilterBase.new(user_id: current_user.id)
    end

    # Apply any filters set on the show page that should further filter the display
    private def show_filter
      @show_filter ||= begin
        filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false, require_service_during_range: false)
        filter.update(filter_params[:filters]) if filter_params[:filters].present?
        filter
      end
    end
    helper_method :show_filter

    # Apply any filters set specifically for the details page that should further filter the display
    private def details_filter
      @details_filter ||= begin
        filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false, require_service_during_range: false)
        filter.update(sub_category_params[:details]) if sub_category_params[:details].present?
        filter
      end
    end
    helper_method :details_filter

    def details_params
      params.permit(:node, :source, :target, :chart)
    end
    helper_method :details_params

    private def set_report
      @report = report_class.find(params[:id].to_i)
    end

    # Since this report uses the hud version of report instance, and it isn't STI
    # we need to limit to those with a report name matching this one
    private def report_scope
      report_class.
        visible_to(current_user)
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id, enforce_one_year_range: false, require_service_during_range: false)
      @filter.update(filter_params[:filters]) if filter_params[:filters].present?
    end

    def filter_params
      site_coc_codes = GrdaWarehouse::Config.default_site_coc_codes || [@filter.coc_code_options_for_select(user: current_user).first]
      default_options = {
        sub_population: :clients,
        coc_codes: site_coc_codes,
      }
      return { filters: default_options } unless params[:filters].present?

      filters = params.permit(filters: @filter.known_params)
      filters[:filters][:coc_codes] ||= site_coc_codes
      filters[:filters][:chronic_status] = params[:filters].try(:[], :chronic_at_entries)&.first
      filters
    end
    helper_method :filter_params

    def sub_category_params
      site_coc_codes = GrdaWarehouse::Config.default_site_coc_codes || [@filter.coc_code_options_for_select(user: current_user).first]
      default_options = {
        sub_population: :clients,
        coc_codes: site_coc_codes,
      }
      return { details: default_options } unless params[:details].present?

      filters = params.permit(details: @filter.known_params)
      filters[:details][:coc_codes] ||= site_coc_codes
      filters[:details][:chronic_status] = params[:details].try(:[], :chronic_at_entries)&.first
      filters
    end
    helper_method :sub_category_params

    private def filter_class
      ::Filters::HudFilterBase
    end

    private def flash_interpolation_options
      { resource_name: @report.title }
    end

    def formatted_cell(cell)
      return view_context.content_tag(:pre, JSON.pretty_generate(cell)) if cell.is_a?(Array) || cell.is_a?(Hash)
      return view_context.yes_no(cell) if cell.in?([true, false])

      cell
    end
    helper_method :formatted_cell

    def report_class
      SystemPathways::Report
    end
  end
end
