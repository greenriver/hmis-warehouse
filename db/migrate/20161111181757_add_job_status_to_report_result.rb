class AddJobStatusToReportResult < ActiveRecord::Migration
  def change
    remove_reference :report_results, :delayed_job, unique: true
    add_column :report_results, :job_status, :string
  end
end
