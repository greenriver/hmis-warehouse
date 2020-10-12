class AddErrorsToHudReports < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_cells, :error_messages, :text
  end
end
