class AddPercentCompleteToHudReportInstances < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_instances, :percent_complete, :float
    add_reference :hud_report_instances, :export
  end
end
