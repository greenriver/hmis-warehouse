class AddGoalReference < ActiveRecord::Migration[6.1]
  def change
    # Not necessarily safe, but we've been having trouble with this running on deployment
    safety_assured { add_reference :simple_report_instances, :goal_configuration, index: { algorithm: :concurrently } }
  end
end
