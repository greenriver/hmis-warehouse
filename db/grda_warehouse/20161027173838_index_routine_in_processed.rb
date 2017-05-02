class IndexRoutineInProcessed < ActiveRecord::Migration
  def change
    add_index :warehouse_clients_processed, :routine
    add_index :Services, :DateDeleted
    add_index :Enrollment, :DateDeleted
    add_index :Exit, :DateDeleted
  end
end
