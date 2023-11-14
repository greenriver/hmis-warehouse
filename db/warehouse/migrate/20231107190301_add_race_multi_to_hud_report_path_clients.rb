class AddRaceMultiToHudReportPathClients < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_path_clients, :race_multi, :string
  end
end
