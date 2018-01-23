class RecreateServiceHistoryServicesIndex < ActiveRecord::Migration
  def change
    add_index :service_history_services, [:date, :service_history_enrollment_id], name: :index_shs_date_en_id
  end
end
