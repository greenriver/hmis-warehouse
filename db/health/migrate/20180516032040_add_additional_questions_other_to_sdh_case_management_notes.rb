class AddAdditionalQuestionsOtherToSdhCaseManagementNotes < ActiveRecord::Migration
  def change
    add_column :sdh_case_management_notes, :place_of_contact_other, :string
    add_column :sdh_case_management_notes, :housing_status_other, :string
  end
end
