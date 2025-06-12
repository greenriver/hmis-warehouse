class AddSexToHudReportPathClients < ActiveRecord::Migration[7.1]
  def change
    add_column :hud_report_path_clients, :sex, :integer
  end
end
