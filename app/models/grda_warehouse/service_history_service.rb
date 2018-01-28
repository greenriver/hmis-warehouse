class GrdaWarehouse::ServiceHistoryService < GrdaWarehouseBase
  include ArelHelper
  belongs_to :service_history_enrollment, inverse_of: :service_history_services

  scope :service, -> { where record_type: service_types }
  scope :extrapolated, -> { where record_type: :extrapolated }

  scope :residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    where(project_type: r_non_homeless)
  end
  scope :hud_residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    hud_project_type(r_non_homeless)
  end

  scope :homeless, -> (chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    where(project_type: project_types)
  end

  scope :hud_homeless, -> (chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    hud_project_type(GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  def self.service_types
    service_types = ['service']
    if GrdaWarehouse::Config.get(:so_day_as_month)
      service_types << 'extrapolated'
    end
  end

  def self.sub_tables
    @table_name ||= table_years.map do |year|
      [year, "service_history_services_#{year}"]
    end.reverse.to_h
  end

  def self.remainder_table
    :service_history_services_remainder
  end

  def self.table_years
    (2000..2050)
  end

  def self.parent_table
    :service_history_services
  end
end