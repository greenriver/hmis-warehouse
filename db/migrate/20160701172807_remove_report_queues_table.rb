class RemoveReportQueuesTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :report_queues
  end
end
