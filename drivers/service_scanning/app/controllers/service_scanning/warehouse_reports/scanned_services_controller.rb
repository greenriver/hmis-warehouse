###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceScanning::WarehouseReports
  class ScannedServicesController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    before_action :require_can_use_service_register!
    before_action :set_filter
    before_action :set_data

    def index
      ids = @dates.values.map(&:values).flatten.flat_map { |m| m[:services].to_a }
      @services = service_class.where(id: ids).
        preload(:project, client: [:processed_service_history])

      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'Service Details.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def detail
      @filter.end = @filter.start
      @project = GrdaWarehouse::Hud::Project.where(id: @filter.effective_project_ids)&.first
      ids = @dates[@filter.start].values.flat_map { |m| m[:services] }
      @services = service_class.where(id: ids).
        preload(:project, :client)
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'Service Details.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def most_recent_hmis_service
      most_recent_dates_of_service = @services.map do |service|
        service.client&.date_of_last_service
      end.compact
      @most_recent_hmis_service ||= GrdaWarehouse::ServiceHistoryService.
        joins(:service_history_enrollment, :client).
        preload(:service_history_enrollment, :client).
        order(date: :asc).
        where(client_id: @services.select(:client_id)).
        where(date: most_recent_dates_of_service).
        index_by(&:client_id).
        map do |client_id, service|
          en = service.service_history_enrollment
          project_id = en.project_id
          data_source_id = en.data_source_id
          project_name = en.project_name
          confidential = service.client.project_confidential?(project_id: project_id, data_source_id: data_source_id)
          clean_name = if ! confidential
            project_name
          else
            GrdaWarehouse::Hud::Project.confidential_project_name
          end
          [
            client_id,
            [
              client_id,
              service.date,
              clean_name,
            ],
          ]
        end.to_h
    end
    helper_method :most_recent_hmis_service

    def most_recent_scan_service
      @most_recent_scan_service ||= service_class.joins(:project).
        where(client_id: @services.select(:client_id)).
        order(provided_at: :asc).
        pluck(:client_id, :provided_at, :ProjectName).
        index_by(&:first)
    end
    helper_method :most_recent_scan_service

    private def set_data
      @dates = begin
        date_scope = service_class.
          joins(:project).
          preload(:project).
          where(project_id: @filter.effective_project_ids, provided_at: @filter.range)
        date_scope = date_scope.where(type: @filter.service_type_class) if @filter.service_type.present?
        date_scope = date_scope.where(other_type: @filter.other_type) if @filter.other_type.present?
        dates = {}

        date_scope.each do |row|
          dates[row.provided_at.to_date] ||= {}
          dates[row.provided_at.to_date][row.project.id] ||= {
            clients: Set.new,
            services: Set.new,
            project: row.project,
          }
          dates[row.provided_at.to_date][row.project.id][:clients] << row.client_id
          dates[row.provided_at.to_date][row.project.id][:services] << row.id
        end
        dates
      end
    end

    private def service_class
      ServiceScanning::Service
    end

    private def set_filter
      @filter = ServiceScanning::Filters::Scan.new(user_id: current_user.id)
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
    end

    private def filter_params
      params.permit(
        filters: [
          :start,
          :end,
          :service_type,
          :other_type,
          project_ids: [],
          project_group_ids: [],
        ],
      )
    end
  end
end
