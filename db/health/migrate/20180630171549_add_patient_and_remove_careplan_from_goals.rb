class AddPatientAndRemoveCareplanFromGoals < ActiveRecord::Migration
  def change
    add_reference :health_goals, :patient, index: true, foreign_key: true
    remove_column :health_goals, :careplan_id, :integer
  end
end
