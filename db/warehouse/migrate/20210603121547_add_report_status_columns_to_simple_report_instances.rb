class AddReportStatusColumnsToSimpleReportInstances < ActiveRecord::Migration[5.2]
  def change
    remove_column :simple_report_instances, :status, :string
    add_column :simple_report_instances, :started_at, :datetime
    add_column :simple_report_instances, :completed_at, :datetime
    add_column :simple_report_instances, :failed_at, :datetime
  end
end
