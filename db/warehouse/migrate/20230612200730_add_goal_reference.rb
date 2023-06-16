class AddGoalReference < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_reference :simple_report_instances, :goal_configuration, index: { algorithm: :concurrently }
  end
end
