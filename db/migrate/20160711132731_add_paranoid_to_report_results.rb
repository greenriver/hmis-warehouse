class AddParanoidToReportResults < ActiveRecord::Migration
  def change
    add_column :report_results, :deleted_at, :datetime
    add_index :report_results, :deleted_at
  end
end
