class AddClientAuditPermissions < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_audit_clients, :boolean, null: false, default: false
  end
end
