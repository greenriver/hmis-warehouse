class AddErrorDetailsToHudReportInstance < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_instances, :error_details, :text
  end
end
