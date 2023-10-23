class AddDvOccurredToHudReportAprClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_apr_clients, :domestic_violence_occurred, :integer
  end
end
