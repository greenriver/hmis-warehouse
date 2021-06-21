class AddCohortPrecalculatedsToWarehouseClientProcessed < ActiveRecord::Migration[5.2]
  def change
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_es, :jsonb
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_sh, :jsonb
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_th, :jsonb
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_so, :jsonb
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_psh, :jsonb
    add_column :warehouse_clients_processed, :cohorts_ongoing_enrollments_rrh, :jsonb
  end
end
