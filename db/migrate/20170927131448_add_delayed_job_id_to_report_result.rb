class AddDelayedJobIdToReportResult < ActiveRecord::Migration[4.2]
  def change
    add_reference :report_results, :delayed_job
  end
end
