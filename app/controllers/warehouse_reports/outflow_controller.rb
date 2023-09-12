###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class OutflowController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :set_report
    before_action :set_modal_size

    def index
    end

    def details
      raise 'Key required' if params[:key].blank?

      @key = @report.metrics.keys.detect { |key| key.to_s == params[:key] }

      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=outflow-#{@key}.xlsx"
        end
        format.html do
          @enrollments = @report.enrollments_for(@key)
        end
      end
    end

    def describe_computations
      path = 'app/views/warehouse_reports/outflow/README.md'
      description = File.read(path)
      markdown = Redcarpet::Markdown.new(::TranslatedHtml)
      markdown.render(description)
    end
    helper_method :describe_computations

    private def set_report
      @filter = ::Filters::OutflowReport.new(user_id: current_user.id).set_from_params(filter_options)
      @report = GrdaWarehouse::WarehouseReports::OutflowReport.new(@filter, current_user)
    end

    private def filter_options
      if params[:filter].present?
        opts = params.require(:filter).permit(
          :start,
          :end,
          :sub_population,
          :no_service_after_date,
          :limit_to_vispdats,
          :require_homeless_enrollment,
          :hoh_only,
          age_ranges: [],
          veteran_statuses: [],
          genders: [],
          races: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
          project_type_numbers: [],
          no_recent_service_project_ids: [],
        )
        if opts[:start].to_date > opts[:end].to_date
          start = opts[:end]
          opts[:end] = opts[:start]
          opts[:start] = start
        end
        opts[:project_ids] = cleanup_ids(opts[:project_ids])
        opts[:organization_ids] = cleanup_ids(opts[:organization_ids])
        opts[:no_recent_service_project_ids] = cleanup_ids(opts[:no_recent_service_project_ids])
        opts[:project_group_ids] = cleanup_ids(opts[:project_group_ids])
        opts[:races] = opts[:races].select { |r| ::HudUtility2024.races.include?(r) } if opts[:races].present?
        opts[:genders] = opts[:genders].reject(&:blank?).map(&:to_i) if opts[:genders].present?
        opts
      else
        {
          start: default_start.to_date,
          end: default_end.to_date,
          no_service_after_date: default_no_service_after_date,
          project_type_numbers: HudUtility2024.homeless_project_types,
          sub_population: :clients,
        }
      end
    end
    helper_method :filter_options

    private def cleanup_ids(array)
      array&.select(&:present?)&.map(&:to_i) || []
    end

    private def default_start
      3.months.ago.beginning_of_month
    end

    private def default_no_service_after_date
      Date.current - 90.days
    end

    private def default_end
      1.months.ago.end_of_month
    end

    private def set_modal_size
      @modal_size = :xl
    end
  end
end
