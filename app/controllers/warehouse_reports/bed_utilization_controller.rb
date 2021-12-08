###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class BedUtilizationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization

    before_action :set_filter

    def index
      if @filter.valid? && @filter.effective_project_ids.reject(&:zero?).any?
        @projects_with_counts = {}

        GrdaWarehouse::Hud::Project.where(id: @filter.effective_project_ids).
          preload(:inventories).find_each do |project|
            @projects_with_counts[project.id] ||= OpenStruct.new(
              id: project.id,
              name: project.ProjectName,
              project_type: project.compute_project_type,
              clients: average(client_count(project)).round,
              beds: average_inventory_count(project, :BedInventory),
              bed_utilization: 0,
              households: average(household_count(project)).round,
              units: average_inventory_count(project, :UnitInventory),
              unit_utilization: 0,
            )
            clients = @projects_with_counts[project.id].clients
            beds = @projects_with_counts[project.id].beds
            @projects_with_counts[project.id][:bed_utilization] = (clients.to_f / beds * 100).round if clients.positive? && beds.positive?

            households = @projects_with_counts[project.id].households
            units = @projects_with_counts[project.id].units
            @projects_with_counts[project.id][:unit_utilization] = (households.to_f / units * 100).round if households.positive? && units.positive?
          end
      end
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = "Bed Utilization #{Time.current.to_s.delete(',')}.xlsx"
          render(xlsx: 'index', filename: filename)
        end
      end
    end

    private def client_count(project)
      query = GrdaWarehouse::ServiceHistoryService.
        joins(:service_history_enrollment).
        service_between(
          start_date: @filter.start,
          end_date: @filter.end,
        ).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.where(project_id: project.id)).
        select(nf('concat', [shs_t[:client_id], shs_t[:date]]).to_sql)
      query = query.where(homeless: false) if project.ph? # limit PH to after move-in
      query.distinct.count
    end

    private def household_count(project)
      query = GrdaWarehouse::ServiceHistoryService.
        joins(:service_history_enrollment).
        service_between(start_date: @filter.start, end_date: @filter.end).
        merge(GrdaWarehouse::ServiceHistoryEnrollment.where(project_id: project.id)).
        select(nf('concat', [she_t[:head_of_household_id], shs_t[:date]]).to_sql)
      query = query.where(homeless: false) if project.ph? # limit PH to after move-in
      query.distinct.count
    end

    private def average_inventory_count(project, field)
      project.inventories.map { |i| i.average_daily_inventory(range: @filter.as_date_range, field: field) }.sum
    end

    private def average(count)
      return 0 unless count.positive?

      count.to_f / @filter.range.count
    end

    def client_counts_by_project_id
      @client_counts_by_project_id ||= service_scope.distinct.group(p_t[:id].to_sql).count(:client_id)
    end

    def set_filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id).update(report_params)
    end

    private def report_params
      return nil unless params[:report].present?

      params.require(:report).
        permit(
          :start_date,
          :end_date,
          project_ids: [],
          organization_ids: [],
          data_source_ids: [],
        )
    end
  end
end
