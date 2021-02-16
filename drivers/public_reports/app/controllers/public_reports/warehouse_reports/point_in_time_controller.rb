###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PublicReports::WarehouseReports
  class PointInTimeController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_report, only: [:show, :destroy, :update, :edit, :raw]

    def index
      @report = report_source.new
      @filter = filter_class.new(user_id: current_user.id).set_from_params(filter_params[:filters])
      @reports = report_scope.order(id: :desc).page(params[:page]).per(25)
    end

    def create
      @filter = filter_class.new(user_id: current_user.id).set_from_params(filter_params[:filters])
      options = {
        start_date: @filter.start,
        end_date: @filter.end,
        filter: @filter.for_params,
        user_id: current_user.id,
        state: :queued,
      }
      @report = report_source.create(options)
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: public_reports_warehouse_reports_point_in_time_index_path)
    end

    def update
      if params.dig(:public_reports_point_in_time, :published_url).present?
        @report.publish!(render_to_string(:raw, layout: false))
        respond_with(@report, location: public_reports_warehouse_reports_point_in_time_path(@report))
      else
        redirect_to(action: :edit)
      end
    end

    def raw
      params[:pp] = 'disabled' # disable rack-mini-profiler
      render(layout: false)
    end

    def show
      redirect_to action: :edit unless @report.published?
    end

    def edit
      redirect_to action: :show if @report.published?
    end

    def destroy
      @report.destroy
      respond_with(@report)
    end

    def filter_params
      options = params.permit(
        filters: [
          :start,
          :end,
          coc_codes: [],
          project_types: [],
          project_type_numbers: [],
          data_source_ids: [],
          organization_ids: [],
          project_ids: [],
          project_group_ids: [],
        ],
      )
      if options.blank?
        options = {
          filters: {
            start: 4.years.ago.beginning_of_year.to_date,
            end: 1.years.ago.end_of_year.to_date,
          },
        }
      end
      options[:filters][:enforce_one_year_range] = false
      options
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    private def report_scope
      report_source.viewable_by(current_user)
    end

    private def report_source
      PublicReports::PointInTime
    end

    private def flash_interpolation_options
      { resource_name: 'Public Report' }
    end
  end
end
