class AddClientToVpr < ActiveRecord::Migration[6.1]
  def change
    add_reference :health_flexible_service_vprs, :client
    add_column :health_flexible_service_vprs, :medicaid_id, :string
    add_reference :health_flexible_service_vprs, :aco

    change_column_null :health_flexible_service_vprs, :patient_id, true
  end
end
