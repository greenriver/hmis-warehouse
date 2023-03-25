class AddClientCreatedDateToAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :client_created_at, :datetime
  end
end
