class CreateSdhCaseManagementNotes < ActiveRecord::Migration[4.2]
  def change
    create_table :sdh_case_management_notes do |t|
      t.belongs_to :user
      t.belongs_to :patient
      t.timestamps
    end
  end
end
