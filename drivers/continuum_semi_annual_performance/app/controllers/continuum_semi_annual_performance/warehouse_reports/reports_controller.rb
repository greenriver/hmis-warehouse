###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ContinuumSemiAnnualPerformance::WarehouseReports
  # Base for the Mid-Year and End of Year controllers; it has no routes of its own.
  class ReportsController < ApplicationControllerV2
    # Declared before the filter concerns so an unauthorized request stops before set_filter runs.
    authorize_with { current_user.can_view_any_reports? && report_class.definition_viewable_by?(current_user) }

    include BaseFilters
    include HistoryFilter

    helper ContinuumSemiAnnualPerformance::ReportsHelper

    FILTER_PARAMS = [
      :start,
      :end,
      { coc_codes: [], project_ids: [], project_type_codes: [], organization_ids: [], data_source_ids: [], project_group_ids: [] },
    ].freeze

    before_action :set_report, only: [:show, :destroy, :approval, :reload_from_csv]

    def index
      @pagy, @reports = pagy(apply_view_filters(report_scope).ordered)
      @report = report_class.new(user_id: current_user.id)
      offer_project_types
      assign_form_defaults
      filters
    end

    def create
      @report = report_class.new(user_id: current_user.id)
      @report.filter = @filter
      @filter.errors.add(:project_ids, 'must include at least one project') if @filter.valid? && @report.included_project_ids.empty?

      if @filter.errors.empty?
        @report.save!
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        redirect_to(@report.index_path, notice: "#{@report.title} queued.")
      else
        @pagy, @reports = pagy(apply_view_filters(report_scope).ordered)
        set_view_filter
        offer_project_types
        filters
        render :index, status: :unprocessable_content
      end
    end

    def show
      return render 'continuum_semi_annual_performance/warehouse_reports/reports/running' unless @report.completed?

      @tab = @report.tabs.map(&:to_s).include?(params[:tab].to_s) ? params[:tab].to_s : 'summary'
    end

    def destroy
      @report.destroy
      redirect_to(@report.index_path, notice: "#{@report.title} removed.")
    end

    def approval
      @report.approve!(user: current_user, approved: params[:approved] == '1') if @report.completed? && !@report.purged?
      redirect_to(@report.show_path)
    end

    def reload_from_csv
      return redirect_to(@report.show_path) unless @report.purged?

      result = Reports::ReloadReportFromCsvService.new(@report).reload!
      if result[:success]
        flash[:notice] = "Report data reloaded successfully. #{result[:reloaded_counts].values.sum} records restored."
      else
        flash[:error] = "Failed to reload report data: #{result[:errors].join(', ')}"
      end
      redirect_to(@report.show_path)
    end

    private def report_class
      raise NotImplementedError
    end

    private def report_scope
      report_class.viewable_by(current_user)
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    private def filter_class
      ContinuumSemiAnnualPerformance::Filter
    end

    private def filter_params
      return {} if params[:filters].blank?

      params.permit(filters: FILTER_PARAMS)
    end
    helper_method :filter_params

    # The project type picker lists the filter's default codes. Set on the instance for the form only:
    # a class-level default would be used whenever the submitted list is empty.
    private def offer_project_types
      @filter.default_project_type_codes = @report.default_project_type_codes
    end

    # The form pre-selects every project type; the stored filter on create holds only what was submitted.
    private def assign_form_defaults
      return if params[:filters].present?

      previous_report = report_scope.where(user_id: current_user.id).last
      if previous_report
        @filter.update(previous_report.options)
      else
        @filter.project_type_codes = @report.default_project_type_codes
      end
    end

    private def path_for_clear_view_filter
      @report.index_path
    end
    helper_method :path_for_clear_view_filter

    private def can_view_all_reports?
      current_user.can_view_all_reports?
    end
    helper_method :can_view_all_reports?
  end
end
