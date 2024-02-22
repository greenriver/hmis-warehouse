class SetDefaultsForExistingHudReportCells < ActiveRecord::Migration[6.1]
  def up
    a_t = HudReports::ReportCell.arel_table
    # Find any rows where the result is a number, and > 0
    query = <<~SQL
      CAST("hud_report_cells"."summary" AS varchar) ~ E'^\\\\d+$'
      AND CAST(CAST("hud_report_cells"."summary" AS varchar) AS integer) > 0
    SQL

    sql = HudReports::ReportCell.where(Arel.sql(query))
    sql.update_all(any_members: true)
  end
end
