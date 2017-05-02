class ConvertServiceHistoryIdToBigint < ActiveRecord::Migration
  def up
    # execute "ALTER TABLE warehouse_client_service_history DROP CONSTRAINT PK__warehous__3213E83F3E8E1B16"
    # change_column :warehouse_client_service_history, :id, :bigint, null: false
    # execute "ALTER TABLE warehouse_client_service_history ADD CONSTRAINT PK__warehous__3213E83F3E8E1B16 PRIMARY KEY (id)"
  end

end
