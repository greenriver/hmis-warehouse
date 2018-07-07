class UpdatesToQualifyingActivities < ActiveRecord::Migration
  def change
    remove_column :qualifying_activities, :note_id, :integer
    add_column :qualifying_activities, :source_type, :string
    add_column :qualifying_activities, :source_id, :integer
    add_column :qualifying_activities, :claim_submitted_on, :datetime
    add_column :qualifying_activities, :date_of_activity, :datetime
    add_column :qualifying_activities, :user_id, :integer
    add_column :qualifying_activities, :user_full_name, :string
  end
end
