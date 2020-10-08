class RebuildAprRaceColumn < ActiveRecord::Migration[5.2]
  def change
    remove_column :hud_report_apr_clients, :race, :jsonb
    add_column :hud_report_apr_clients, :race, :integer
  end
end
