class AddHealthFileToSdhCaseManagementNotes < ActiveRecord::Migration[4.2]
  def change
    add_reference :sdh_case_management_notes, :health_file, index: true, foreign_key: true
  end
end
