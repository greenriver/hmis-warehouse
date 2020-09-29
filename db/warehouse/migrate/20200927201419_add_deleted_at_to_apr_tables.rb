class AddDeletedAtToAprTables < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_cells, :deleted_at, :datetime
    add_column :hud_report_instances, :deleted_at, :datetime
    add_column :hud_report_apr_clients, :deleted_at, :datetime
    add_column :hud_report_universe_members, :deleted_at, :datetime
    add_column :hud_report_apr_living_situations, :deleted_at, :datetime
  end
end
