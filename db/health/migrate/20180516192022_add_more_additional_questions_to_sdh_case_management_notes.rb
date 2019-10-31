class AddMoreAdditionalQuestionsToSdhCaseManagementNotes < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :sdh_case_management_notes, :housing_placement_date, :datetime
    add_column :sdh_case_management_notes, :client_action, :string
    add_column :sdh_case_management_notes, :notes_from_encounter, :text
    add_column :sdh_case_management_notes, :next_steps, :text
    add_column :sdh_case_management_notes, :client_phone_number, :string
  end
end
