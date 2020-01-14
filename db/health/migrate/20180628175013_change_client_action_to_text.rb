class ChangeClientActionToText < ActiveRecord::Migration[4.2]
  def change
    change_column :sdh_case_management_notes, :client_action, :text
  end
end
