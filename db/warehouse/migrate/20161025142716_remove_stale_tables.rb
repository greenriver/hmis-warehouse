class RemoveStaleTables < ActiveRecord::Migration
  def up
    drop_table :clients_processed if GrdaWarehouseBase.connection.table_exists? :clients_processed
    drop_table :clients_unduplicated if GrdaWarehouseBase.connection.table_exists? :clients_unduplicated
    drop_table :client_service_history if GrdaWarehouseBase.connection.table_exists? :client_service_history
  end
end
