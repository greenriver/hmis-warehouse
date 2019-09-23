class AddLgbtqFromHmisToWarehouseClientProcessed < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :lgbtq_from_hmis, :string
  end
end
