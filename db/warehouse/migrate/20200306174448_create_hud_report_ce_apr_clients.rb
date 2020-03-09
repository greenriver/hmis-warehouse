class CreateHudReportCeAprClients < ActiveRecord::Migration[5.2]
  def change
    create_table :hud_report_ce_apr_clients do |t|

      t.timestamps
    end
  end
end
