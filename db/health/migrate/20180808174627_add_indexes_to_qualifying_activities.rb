class AddIndexesToQualifyingActivities < ActiveRecord::Migration[4.2][4.2]
  def change
    add_index :qualifying_activities, :patient_id
    add_index :qualifying_activities, :date_of_activity
    add_index :qualifying_activities, :source_type
    add_index :qualifying_activities, :source_id
    add_index :qualifying_activities, :claim_id
  end
end
