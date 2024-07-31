class AddPayForSuccessToHudAprClients < ActiveRecord::Migration[7.0]
  def change
    add_column :hud_report_apr_clients, :pay_for_success, :boolean, default: false
  end
end
