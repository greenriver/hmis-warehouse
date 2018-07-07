class AdjustmentsToSdhCaseManagementNotesAndQualifyingActivities < ActiveRecord::Migration
  def change
    add_column :sdh_case_management_notes, :completed_on, :datetime
    add_column :qualifying_activities, :follow_up, :string
  end
end
