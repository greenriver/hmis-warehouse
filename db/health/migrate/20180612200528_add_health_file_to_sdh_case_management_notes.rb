class AddHealthFileToSdhCaseManagementNotes < ActiveRecord::Migration
  def change
    add_reference :sdh_case_management_notes, :health_file, index: true, foreign_key: true
  end
end
