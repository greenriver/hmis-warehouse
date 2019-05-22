module Reporting::DataQualityReports
  class Project < ReportingBase
    include ArelHelper

    self.table_name = :warehouse_data_quality_report_projects

    def calculate_coc_code
      project.project_cocs.map(&:CoCCode).uniq.join(', ')
    end
    def calculate_funder project:
      project.funders.map(&:GrantID).uniq.join(', ')
    end
    def calculate_geocode project:
      project.geographies.map(&:Geocode).uniq.join(', ')
    end
    def calculate_geography_type project:
      project.geographies.map do |m|
        HUD::geography_type(m.GeographyType)
      end.uniq.join(', ')
    end
    def calculate_unit_inventory project:, report_range:
      project.inventories.within_range(report_range).map do |m|
        m[:UnitInventory] || 0
      end.sum
    end
    def calculate_bed_inventory
      project.inventories.within_range(report_range).map do |m|
        m[:BedInventory] || 0
      end.sum
    end
    def calculate_housing_type
      project.inventories.map do |m|
        HUD::housing_type(m.HousingType)
      end.uniq.join(', ')
    end
    def calculate_average_nightly_clients
    end
    def calculate_average_nightly_households
    end
    def calculate_average_bed_utilization
    end
    def calculate_average_unit_utilization
    end

    # NOTE: this relies on service_history_service, not source data
    def calculate_nightly_client_census project:, report_range;
      GrdaWarehouse::ServiceHistoryService.where(date: report_range, project_id: project.id).
        group(:date).select(:client_id).distinct.count
    end

    # NOTE: this relies on service_history_service, not source data
    def calculate_nightly_household_census
    end
  end
end