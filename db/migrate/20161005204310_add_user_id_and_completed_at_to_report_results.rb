class AddUserIdAndCompletedAtToReportResults < ActiveRecord::Migration
  def up
    add_column :report_results, :completed_at, :datetime
    add_reference :report_results, :user
    add_foreign_key :report_results, :users
    reports = ReportResult.all
    reports.each do |r|
      updated = r.updated_at
      r.update(completed_at: updated)
    end
  end

  def down
    remove_column :report_results, :completed_at
    remove_column :report_results, :user_id
  end
end
