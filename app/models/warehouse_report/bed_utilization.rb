###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::BedUtilization < OpenStruct
  include ArelHelper
  attr_accessor :filter

  def self.viewable_by(user)
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
      viewable_by(user).exists?
  end

  def self.url
    'warehouse_reports/bed_utilization'
  end

  def filter # rubocop:disable Lint/DuplicateMethods
    self[:filter]
  end

  def report
    return {} unless filter&.valid? && filter&.effective_project_ids&.reject(&:zero?)&.any?

    @report = {}.tap do |report_data|
      GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids).
        preload(:inventories).find_each do |project|
          report_data[project.id] ||= OpenStruct.new(
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
          clients = report_data[project.id].clients
          beds = report_data[project.id].beds
          report_data[project.id][:bed_utilization] = (clients.to_f / beds * 100).round if clients.positive? && beds.positive?

          households = report_data[project.id].households
          units = report_data[project.id].units
          report_data[project.id][:unit_utilization] = (households.to_f / units * 100).round if households.positive? && units.positive?
        end
    end
  end

  private def client_count(project)
    query = GrdaWarehouse::ServiceHistoryService.
      joins(:service_history_enrollment).
      service_between(
        start_date: filter.start,
        end_date: filter.end,
      ).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.where(project_id: project.id)).
      select(nf('concat', [shs_t[:client_id], shs_t[:date]]).to_sql)
    query = query.where(homeless: false) if project.ph? # limit PH to after move-in
    query.distinct.count
  end

  private def household_count(project)
    query = GrdaWarehouse::ServiceHistoryService.
      joins(:service_history_enrollment).
      service_between(start_date: filter.start, end_date: filter.end).
      merge(GrdaWarehouse::ServiceHistoryEnrollment.where(project_id: project.id)).
      select(nf('concat', [she_t[:head_of_household_id], shs_t[:date]]).to_sql)
    query = query.where(homeless: false) if project.ph? # limit PH to after move-in
    query.distinct.count
  end

  private def average_inventory_count(project, field)
    project.inventories.map { |i| i.average_daily_inventory(range: filter.as_date_range, field: field) }.sum
  end

  private def average(count)
    return 0 unless count.positive?

    count.to_f / filter.range.count
  end
end
