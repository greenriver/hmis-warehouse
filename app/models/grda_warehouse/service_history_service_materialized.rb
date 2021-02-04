###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::ServiceHistoryServiceMaterialized < GrdaWarehouseBase
  self.table_name = :service_history_services_materialized
  include ArelHelper
  include ServiceHistoryServiceConcern

  belongs_to :service_history_enrollment, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

  scope :hud_project_type, ->(project_types) do
    where(project_type: project_types)
  end

  def self.project_type_column
    :project_type
  end

  def self.refresh!
    sql = 'REFRESH MATERIALIZED VIEW service_history_services_materialized;'
    connection.execute(sql)
  end

  def self.view_sql
    'CREATE MATERIALIZED VIEW IF NOT EXISTS service_history_services_materialized as select * from service_history_services;'
  end

  def self.remove_view_sql
    'DROP MATERIALIZED VIEW IF EXISTS service_history_services_materialized;'
  end

  def self.rebuild!
    connection.execute(remove_view_sql)
    connection.execute(view_sql)
    connection.add_index :service_history_services_materialized, :id, unique: true
    connection.add_index :service_history_services_materialized, [:client_id, :project_type, :record_type], name: :index_shsm_c_id_p_type_r_type
    # self.connection.add_index :service_history_services_materialized, [:project_type, :record_type], name: :index_shsm_p_type_r_type
    # self.connection.add_index :service_history_services_materialized, [:client_id, :homeless], name: :index_shsm_c_id_homeless
    # self.connection.add_index :service_history_services_materialized, [:client_id, :literally_homeless], name: :index_shsm_c_id_literally_homeless
    connection.add_index :service_history_services_materialized, [:homeless, :project_type, :client_id], name: :index_shsm_homeless_p_type_c_id
    connection.add_index :service_history_services_materialized, [:literally_homeless, :project_type, :client_id], name: :index_shsm_literally_homeless_p_type_c_id
    connection.add_index :service_history_services_materialized, [:client_id, :date], name: :index_shsm_c_id_date
    connection.add_index :service_history_services_materialized, :service_history_enrollment_id, name: :index_shsm_shse_id
  end
end
