###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OutcomesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include AjaxModalRails::Controller

    before_action :set_months
    before_action :set_filter
    before_action :set_report
    before_action :set_modal_size

    respond_to :html, :js

    def available_reports
      {
        rrh: {
          class: WarehouseReport::Outcomes::RrhReport,
          index_path: warehouse_reports_rrh_index_path,
          scope: ::Reporting::Housed.rrh,
          project_types: [13],
        },
        psh: {
          class: WarehouseReport::Outcomes::PshReport,
          index_path: warehouse_reports_psh_index_path,
          scope: ::Reporting::Housed.psh,
          project_types: [3, 9, 10],
        },
        es: {
          class: WarehouseReport::Outcomes::EsReport,
          index_path: warehouse_reports_shelter_index_path,
          scope: ::Reporting::Housed.es,
          project_types: [1],
        },
        th: {
          class: WarehouseReport::Outcomes::ThReport,
          index_path: warehouse_reports_th_index_path,
          scope: ::Reporting::Housed.th,
          project_types: [2],
        },
      }
    end

    def index
    end

    def clients
      @clients = if can_see_client_details?
        @report.support_for(params[:metric]&.to_sym, params)
      else
        WarehouseReport::RrhReport::Support.new(clients: [], rows: [], headers: [])
      end
      respond_to do |format|
        format.html do
          render layout: 'ajax_modal_rails/content'
        end
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=#{@report.title} - Supporting Data.xlsx"
        end
      end
    end

    def describe_computations
      description = File.read("app/views/warehouse_reports/outcomes/#{@report.class.name.demodulize.underscore}/README.md")
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations

    def report_index_path
      available_reports[params[:scope]][:index_path]
    end
    helper_method :report_index_path

    private def set_modal_size
      @modal_size = :xl
    end

    private def reporting_scope
      available_reports[params[:scope]][:scope]
    end

    private def set_months
      start_date = reporting_scope.minimum(:search_start).presence || reporting_scope.minimum(:housed_date).presence || 1.years.ago.to_date
      end_date = reporting_scope.maximum(:housing_exit).presence || Date.current
      @start_months = (start_date.to_date..end_date.to_date).map do |m|
        [m.beginning_of_month, m.beginning_of_month]
      end.uniq.reverse.drop(1).to_h
      @end_months = (start_date.to_date..end_date.to_date).map do |m|
        [m.end_of_month, m.end_of_month]
      end.uniq.reverse.to_h
    end

    private def set_filter
      @filter = WarehouseReport::Outcomes::OutcomesFilter.new(
        default_start: @start_months.values[5],
        default_end: @end_months.values[0],
        user_id: current_user.id,
      )
      @filter.set_from_params(report_params) if params[:filter].present?
      @filter.project_type_numbers = available_reports[params[:scope]][:project_types]

      # force at least a 2 month coverage
      @filter.start = (@filter.end - 1.months).beginning_of_month if @filter.start > @filter.end
    end

    private def report_class
      available_reports[params[:scope]][:class]
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    private def available_projects
      @available_projects ||= project_source.with_project_type(available_reports[params[:scope]][:project_types]).
        joins(:organization).
        pluck(o_t[:OrganizationName].to_sql, :ProjectName, :id).
        map do |org_name, project_name, id|
        ["#{project_name} >> #{org_name}", id]
      end
    end

    private def report_params
      params.require(:filter).permit(shared_params)
    end

    private def passed_params
      params.permit(filter: shared_params)
    end
    helper_method :passed_params

    private def shared_params
      [
        :start,
        :end,
        :sub_population,
        :household_type,
        :race,
        :ethnicity,
        :gender,
        :veteran_status,
        :hoh_only,
        data_source_ids: [],
        organization_ids: [],
        project_ids: [],
        project_group_ids: [],
        coc_codes: [],
      ]
    end

    private def project_ids(project_ids)
      return :all unless project_ids.present?

      project_ids = available_projects.map(&:last).
        select { |m| project_ids.include?(m) }
      return project_ids.map(&:to_i) if project_ids

      :all
    end

    private def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end

    private def can_see_client_details?
      @can_see_client_details ||= if @filter.project_ids == :all
        current_user.can_access_some_version_of_clients?
      else
        true
      end
    end
    helper_method :can_see_client_details?
  end
end
