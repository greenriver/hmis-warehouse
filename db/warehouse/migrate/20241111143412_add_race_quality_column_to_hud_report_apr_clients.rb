class AddRaceQualityColumnToHudReportAprClients < ActiveRecord::Migration[7.0]
  def change
    add_column :hud_report_apr_clients, :race_multi_include_race_none, :jsonb
  end
end
