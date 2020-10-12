class AddStatusToReportCell < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_cells, :status, :string
  end
end
