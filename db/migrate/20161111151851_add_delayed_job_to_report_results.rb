class AddDelayedJobToReportResults < ActiveRecord::Migration
  def change
    add_reference :report_results, :delayed_job, unique: true
  end
end
