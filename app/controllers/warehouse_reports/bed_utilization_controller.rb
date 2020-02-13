###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class BedUtilizationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    before_action :set_filter

    def index
      if @mo.valid?
        @projects_with_counts = {
          totals: OpenStruct.new(
            clients: 0,
            beds: 0,
            units: 0,
            utilization: 0,
          ),
        }
        @mo.organization.projects.each do |project|
          @projects_with_counts[project.id] ||= OpenStruct.new(
            id: project.id,
            name: project.ProjectName,
            project_type: project.compute_project_type,
            clients: 0,
            beds: 0,
            units: 0,
            utilization: 0,
          )
          @projects_with_counts[project.id][:clients] = client_counts_by_project_id[project.id] || 0
          @projects_with_counts[project.id][:beds] = project.inventories.within_range(@mo).map do |inventory|
            inventory.average_daily_inventory(
              range: @mo,
              field: :BedInventory,
            )
          end.sum

          @projects_with_counts[project.id][:units] = project.inventories.within_range(@mo).map do |inventory|
            inventory.average_daily_inventory(
              range: @mo,
              field: :UnitInventory,
            )
          end.sum
          if @projects_with_counts[project.id][:clients].positive? && @projects_with_counts[project.id][:beds].positive?
            @projects_with_counts[project.id][:utilization] = begin
              (@projects_with_counts[project.id][:clients].to_f / @projects_with_counts[project.id][:beds] * 100).round
            rescue StandardError
              0
            end
          end
          @projects_with_counts[:totals][:clients] += @projects_with_counts[project.id][:clients]
          @projects_with_counts[:totals][:beds] += @projects_with_counts[project.id][:beds]
          @projects_with_counts[:totals][:units] += @projects_with_counts[project.id][:units]
        end
        if @projects_with_counts[:totals][:clients].positive? && @projects_with_counts[:totals][:beds].positive?
          @projects_with_counts[:totals][:utilization] = begin
            (@projects_with_counts[:totals][:clients].to_f / @projects_with_counts[:totals][:beds] * 100).round
          rescue StandardError
            0
          end
        end
      else
        @projects_with_counts = (
          begin
            @mo.organization.projects.viewable_by(current_user).map { |p| [p, []] }
           rescue StandardError
             {}
          end
        )
      end
      respond_to :html
    end

    def client_counts_by_project_id
      @client_counts_by_project_id ||= service_scope.distinct.group(p_t[:id].to_sql).count(:client_id)
    end

    def set_filter
      options = {}
      if filter_params[:mo].present?
        start_date = Date.parse "#{filter_params[:mo][:year]}-#{filter_params[:mo][:month]}-1"
        # NOTE: we need to pro-rate the current month
        end_date = [start_date.end_of_month, Date.yesterday].min
        options = filter_params[:mo]
        options[:start] = start_date
        options[:end] = end_date
      end
      @mo = ::Filters::MonthAndOrganization.new options
      @mo.user = current_user
    end

    def filter_params
      params.permit(
        mo: [
          :year,
          :month,
          :org,
        ],
      )
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization.viewable_by(current_user)
    end

    def service_scope
      GrdaWarehouse::ServiceHistoryService.where(date: @mo.range).
        joins(service_history_enrollment: { project: :organization }).
        merge(organization_scope)
    end
  end
end
