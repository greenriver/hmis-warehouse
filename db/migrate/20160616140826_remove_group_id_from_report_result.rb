class RemoveGroupIdFromReportResult < ActiveRecord::Migration[4.2]
  def change
    remove_column :report_results, :report_group, :datetime
  end
end
