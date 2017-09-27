class AddDelayedJobIdToReportResult < ActiveRecord::Migration
  def change
    add_reference :report_results, :delayed_job
  end
end
