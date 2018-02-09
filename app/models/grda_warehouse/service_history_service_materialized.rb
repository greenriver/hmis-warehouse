class GrdaWarehouse::ServiceHistoryServiceMaterialized < GrdaWarehouseBase
  self.table_name = :service_history_services_materialized
  include ArelHelper
  include ServiceHistoryServiceConcern

  scope :hud_project_type, -> (project_types) do
    where(project_type: project_types)
  end

  def self.project_type_column
    :project_type
  end

  def self.refresh!
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