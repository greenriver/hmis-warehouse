class AddAnyMembersToReportCells < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_cells, :any_members, :boolean, default: false, null: false
  end
end
