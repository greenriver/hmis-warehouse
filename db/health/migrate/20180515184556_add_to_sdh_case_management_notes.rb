class AddToSdhCaseManagementNotes < ActiveRecord::Migration
  def change
    add_column :sdh_case_management_notes, :topics, :text
    add_column :sdh_case_management_notes, :title, :string
    add_column :sdh_case_management_notes, :total_time_spent_in_minutes, :integer
    add_column :sdh_case_management_notes, :date_of_contact, :datetime
  end
end
