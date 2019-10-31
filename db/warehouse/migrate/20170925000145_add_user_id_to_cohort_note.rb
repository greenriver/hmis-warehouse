class AddUserIdToCohortNote < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_client_notes, :user_id, :integer, null: false
  end
end
