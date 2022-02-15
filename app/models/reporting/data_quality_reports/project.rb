###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reporting::DataQualityReports
  class Project < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_data_quality_report_projects

    belongs_to :report, class_name: 'GrdaWarehouse::WarehouseReports::Project::DataQuality::Base', foreign_key: :report_id, optional: true
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true

    def calculate_coc_code project:
      project.project_cocs.map(&:CoCCode).uniq.join(', ')
    end
    def calculate_funder project:
      project.funders.map{ |f| HUD.funding_source f.Funder&.to_i }.uniq.join(', ')
    end
    def calculate_geocode project:
      project.project_cocs.map(&:Geocode).uniq.join(', ')
    end
    def calculate_geography_type project:
      project.project_cocs.map do |m|
        HUD::geography_type(m.GeographyType)
      end.uniq.join(', ')
    end

    def calculate_unit_inventory project:, report_range:
      project.inventories.within_range(report_range).map do |inventory|
        inventory.average_daily_inventory(
          range: report_range,
          field: :UnitInventory
        )
      end.sum
    end

    def calculate_bed_inventory project:, report_range:
      project.inventories.within_range(report_range).map do |inventory|
        inventory.average_daily_inventory(
          range: report_range,
          field: :BedInventory
        )
      end.sum
    end

    def calculate_inventory_information_dates project:
      project.inventories.map(&:InformationDate).join(', ')
    end

    # NOTE: this relies on service_history_service, not source data
    # Because we'll need to de-dupe these for the project group, we can't rely on the DB
    # to do the counting, we'll store client ids per date
    def calculate_nightly_client_census project:, report_range:
      @calculate_nightly_client_census ||= begin
        counts = services_scope(project: project, report_range: report_range).
          group(:date).select(:client_id).distinct.count
        report_range.range.each do |date|
          counts[date] ||= 0
        end
        counts
      end
    end

    # NOTE: this relies on service_history_service, not source data
    # Counts unique client_ids only for heads of household
    # Because we'll need to de-dupe these for the project group, we can't rely on the DB
    # to do the counting, we'll store client ids per date
    def calculate_nightly_household_census project:, report_range:
      @calculate_nightly_household_census ||= begin
        counts = services_scope(project: project, report_range: report_range).
          merge(GrdaWarehouse::ServiceHistoryEnrollment.heads_of_households).
          group(:date).select(:client_id).distinct.count
        report_range.range.each do |date|
          counts[date] ||= 0
        end
        counts
      end
    end

    def services_scope project:, report_range:
      # Explicitly ignore extrapolated SO since we're reporting on data collected
      GrdaWarehouse::ServiceHistoryService.where(record_type: :service).
        joins(service_history_enrollment: :project).
        merge(GrdaWarehouse::Hud::Project.where(id: project.id)).
        where(date: report_range.range)
    end

    # these rely on previously calculated values
    def calculate_average_nightly_clients report_range:
      (self.nightly_client_census.values.sum.to_f / report_range.range.count).round rescue 0
    end

    def calculate_average_nightly_households report_range:
      (self.nightly_household_census.values.sum.to_f / report_range.range.count).round rescue 0
    end

    def calculate_average_bed_utilization
      ((self.average_nightly_clients / self.bed_inventory.to_f ) * 100).round rescue 0
    end

    def calculate_average_unit_utilization
      ((self.average_nightly_households / self.unit_inventory.to_f) * 100).round rescue 0
    end

  end
end
