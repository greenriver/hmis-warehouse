class AddAdditionalQuestionsToSdhCaseManagementNotes < ActiveRecord::Migration
  def change
    add_column :sdh_case_management_notes, :place_of_contact, :string
    add_column :sdh_case_management_notes, :housing_status, :string
  end
end
