class AddAdditionalQuestionsToSdhCaseManagementNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :sdh_case_management_notes, :place_of_contact, :string
    add_column :sdh_case_management_notes, :housing_status, :string
  end
end
