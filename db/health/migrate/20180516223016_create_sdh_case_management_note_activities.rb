class CreateSdhCaseManagementNoteActivities < ActiveRecord::Migration
  def change
    create_table :sdh_case_management_note_activities do |t|
      t.integer :note_id
      t.string :mode_of_contact
      t.string :mode_of_contact_other
      t.string :reached_client
      t.string :reached_client_collateral_contact
      t.string :activity
    end
  end
end
