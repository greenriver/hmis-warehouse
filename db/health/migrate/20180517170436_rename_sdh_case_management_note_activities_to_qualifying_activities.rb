class RenameSdhCaseManagementNoteActivitiesToQualifyingActivities < ActiveRecord::Migration[4.2][4.2]
  def change
    rename_table :sdh_case_management_note_activities, :qualifying_activities
  end
end
