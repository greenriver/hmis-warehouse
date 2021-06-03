class AddStatusToSimpleReports < ActiveRecord::Migration[5.2]
  def change
    add_column :simple_report_instances, :status, :string
  end
end
