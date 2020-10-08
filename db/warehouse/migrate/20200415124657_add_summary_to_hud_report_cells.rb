class AddSummaryToHudReportCells < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_cells, :summary, :json
  end
end
