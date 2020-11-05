class MultipleCoCCodesForHudReports < ActiveRecord::Migration[5.2]
  def change
    add_column :hud_report_instances, :coc_codes, :jsonb
  end
end
