class AddQ24ToHudReportAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :sexual_orientation, :integer
    add_column :hud_report_apr_clients, :move_on_assistance_provided, :integer
  end
end
