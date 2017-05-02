class RemoveGroupIdFromReportResult < ActiveRecord::Migration
  def change
    remove_column :report_results, :report_group, :datetime
  end
end
