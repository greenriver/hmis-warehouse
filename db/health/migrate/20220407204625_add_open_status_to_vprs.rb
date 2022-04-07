class AddOpenStatusToVprs < ActiveRecord::Migration[6.1]
  def change
    add_column :health_flexible_service_vprs, :open, :boolean, default: :true
  end
end
