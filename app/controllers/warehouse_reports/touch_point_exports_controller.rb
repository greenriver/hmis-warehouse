###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class TouchPointExportsController < ApplicationController
    include WarehouseReportAuthorization

    before_action :load_report, only: [:show, :destroy]

    def index
      options = { search_scope: touch_point_scope }
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::TouchPointExportsFilter.new(options)
      @reports = report_scope.for_list.
        order(created_at: :desc).
        page(params[:page]).
        per(25)
    end

    def create
      options = { search_scope: touch_point_scope }
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::TouchPointExportsFilter.new(options)
      # allowlist for touchpoint name
      @filter.name = @filter.touch_points_for_user(current_user).detect { |m| m == @filter.name }
      if @filter.name.present?
        @report = report_scope.create(
          parameters: @filter.to_h.except(:search_scope),
          user: current_user,
        )
        ::WarehouseReports::GenericReportJob.perform_later(
          user_id: current_user.id,
          report_class: @report.class.name,
          report_id: @report.id,
        )
        respond_with(@report, location: reports_location)
      else
        @filter.valid?
        @reports = report_scope.for_list.
          order(created_at: :desc).
          page(params[:page]).
          per(25)
        render action: :index
      end
    end

    def show
      respond_to do |format|
        format.xlsx do
          name = @report.parameters['name']
          start_date = @report.parameters['start']
          end_date = @report.parameters['end']
          headers['Content-Disposition'] = "attachment; filename=#{file_name}-#{name} #{start_date&.to_date&.strftime('%F')} to #{end_date&.to_date&.strftime('%F')}.xlsx"
        end
      end
    end

    def destroy
      @report.destroy
      respond_with(@report, location: reports_location)
    end

    def file_name
      'TouchPoints'
    end

    def report_scope
      GrdaWarehouse::WarehouseReports::TouchPoint.for_user(current_user)
    end

    def load_report
      @report = report_scope.find(params[:id].to_i)
    end

    def filter_params
      params.permit(filter: [:name, :start, :end])[:filter]
    end

    def report_source
      GrdaWarehouse::HmisForm.non_confidential
    end

    def touch_point_scope
      GrdaWarehouse::HMIS::Assessment.non_confidential
    end

    def reports_location
      warehouse_reports_touch_point_exports_path
    end

    def report_location(report, args = nil)
      warehouse_reports_touch_point_export_path(report, args)
    end
    helper_method :report_location

    def flash_interpolation_options
      { resource_name: 'Export' }
    end
  end
end
