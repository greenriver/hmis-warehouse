class IndexRoutineInProcessed < ActiveRecord::Migration[4.2]
  def change
    add_index :warehouse_clients_processed, :routine
    add_index :Services, :DateDeleted
    add_index :Enrollment, :DateDeleted
    add_index :Exit, :DateDeleted
  end
end
