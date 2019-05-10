module Dashboards
  class BaseController < ApplicationController
    include ArelHelper

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    before_action :require_can_view_censuses!
    before_action :set_available_months
    before_action :set_chosen_months
    before_action :set_report_months
    before_action :set_project_and_organization_ids
    before_action :set_start_date
    before_action :set_end_date

    def index
      @report = active_report_class.new(months: @report_months, organization_ids: @organization_ids, project_ids: @project_ids)

      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
          @enrollments = @report.enrolled_clients
          @clients = GrdaWarehouse::Hud::Client.where(
            id: @enrollments.distinct.pluck(:client_id)
          ).index_by(&:id)
          @projects = GrdaWarehouse::Hud::Project.where(
            id: @enrollments.distinct.pluck(:project_id)
          ).pluck(:id, :ProjectName).to_h
           @organizations = GrdaWarehouse::Hud::Organization.where(
            id: @enrollments.distinct.pluck(:organization_id)
          ).pluck(:id, :OrganizationName).to_h
        end
      end
    end

    def set_available_months
      @available_months ||= active_report_class.distinct.order(year: :desc, month: :desc).
        pluck(:year, :month).map do |year, month|
          date = Date.new(year, month, 1)
          [[year, month], date.strftime('%B %Y')]
        end.to_h
    end

    def set_chosen_months
      @start_month = params[:choose_report][:start_month] rescue [6.months.ago.year, 6.months.ago.month].to_s
      @end_month = params[:choose_report][:end_month] rescue [1.months.ago.year, 1.months.ago.month].to_s
    end

    def set_report_months
      start_index = @available_months.keys.index(JSON.parse(@start_month))
      end_index = @available_months.keys.index(JSON.parse(@end_month))
      @report_months = @available_months.keys.slice(end_index, start_index) rescue []
    end

    def set_start_date
      (year, month) = @report_months.last
      @start_date = Date.new(year, month, 1) rescue Date.today
    end

    def set_end_date
      (year, month) = @report_months.first
      @end_date = Date.new(year, month, -1) rescue Date.today
    end

    def set_project_and_organization_ids
      @organization_ids = params[:choose_report][:organization_ids].map(&:presence).compact.map(&:to_i) rescue []
      @project_ids = params[:choose_report][:project_ids].map(&:presence).compact.map(&:to_i) rescue []
    end

  end
end