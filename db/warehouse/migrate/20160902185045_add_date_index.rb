class AddDateIndex < ActiveRecord::Migration
  def change
    add_index :warehouse_client_service_history, :date, order: {date: :desc}, name: :service_history_date_desc
  end
end
