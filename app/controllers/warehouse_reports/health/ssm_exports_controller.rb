###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Health
  class SsmExportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :require_can_view_aggregate_health!
    before_action :require_can_administer_health!
    before_action :set_filter, only: [:index, :create]
    before_action :set_report, only: [:show, :destroy]

    def index
      @reports = report_scope.order(created_at: :desc).
        select(:id, :user_id, :options, :started_at, :completed_at).
        page(params[:page]).per(25)
    end

    def create
      @report = Health::SsmExport.create(options: filter_params, user_id: current_user.id)
      ::WarehouseReports::GenericReportJob.perform_later(
        user_id: current_user.id,
        report_class: @report.class.name,
        report_id: @report.id,
      )
      respond_with(@report, location: warehouse_reports_health_ssm_exports_path)
    end

    def destroy
      @report.destroy
      respond_with(@report, location: warehouse_reports_health_ssm_exports_path)
    end

    def show
      respond_to do |format|
        format.xlsx do
          headers['Content-Disposition'] = "attachment; filename=\"SSM-#{@report.filter.start&.to_date&.strftime('%F')} to #{@report.filter.end&.to_date&.strftime('%F')}.xlsx\""
        end
      end
    end

    private def set_filter
      options = {}
      options.merge!(filter_params) if filter_params.present?
      @filter = ::Filters::DateRange.new(options)
    end

    private def filter_params
      @filter_params = {}
      @filter_params.merge!(report_params[:filter]) if report_params[:filter].present?
      @filter_params
    end

    private def report_params
      params.permit(filter: [:start, :end])
    end

    private def set_report
      @report = report_scope.find(params[:id].to_i)
    end

    private def report_scope
      Health::SsmExport.where(user_id: current_user.id)
    end

    def flash_interpolation_options
      { resource_name: 'SSM Export' }
    end
  end
end
