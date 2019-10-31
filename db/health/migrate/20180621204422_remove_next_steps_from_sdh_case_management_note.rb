class RemoveNextStepsFromSdhCaseManagementNote < ActiveRecord::Migration[4.2]
  def change
    remove_column :sdh_case_management_notes, :next_steps, :text
  end
end
