class RenameSdhCaseManagementNoteActivitiesToQualifyingActivities < ActiveRecord::Migration
  def change
    rename_table :sdh_case_management_note_activities, :qualifying_activities
  end
end
