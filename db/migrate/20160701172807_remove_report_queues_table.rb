class RemoveReportQueuesTable < ActiveRecord::Migration
  def change
    drop_table :report_queues
  end
end
