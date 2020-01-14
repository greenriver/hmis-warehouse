class AddLgbtqFromHmisToWarehouseClientProcessed < ActiveRecord::Migration[4.2]
  def change
    add_column :warehouse_clients_processed, :lgbtq_from_hmis, :string
  end
end
