class AddClientToVpr < ActiveRecord::Migration[6.1]
  def change
    add_reference :health_flexible_service_vprs, :client
    add_column :health_flexible_service_vprs, :medicaid_id, :string
    add_reference :health_flexible_service_vprs, :aco
  end
end
