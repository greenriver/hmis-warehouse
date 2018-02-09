class GrdaWarehouse::ServiceHistoryServiceMaterialized < GrdaWarehouseBase
  self.table_name = :service_history_services_materialized
  include ArelHelper

  scope :service, -> { where record_type: service_types }
  scope :extrapolated, -> { where record_type: :extrapolated }

  scope :residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    where(project_type: r_non_homeless)
  end
  scope :hud_residential_non_homeless, -> do
    r_non_homeless = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    where(project_type: r_non_homeless)
  end

  scope :homeless, -> (chronic_types_only: false) do
    if chronic_types_only
      project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    else
      project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    where(project_type: project_types)
  end

  scope :hud_homeless, -> (chronic_types_only: true) do
    where(project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  def self.service_types
    service_types = ['service']
    if GrdaWarehouse::Config.get(:so_day_as_month)
      service_types << 'extrapolated'
    end
  end

  def self.refresh
    sql = "REFRESH MATERIALIZED VIEW service_history_services_materialized;"
    self.connection.execute(sql)
  end

  def self.view_sql
    "CREATE MATERIALIZED VIEW IF NOT EXISTS service_history_services_materialized as select * from service_history_services;"
  end

  def self.remove_view_sql
    "DROP MATERIALIZED VIEW IF EXISTS service_history_services_materialized;"
  end
end