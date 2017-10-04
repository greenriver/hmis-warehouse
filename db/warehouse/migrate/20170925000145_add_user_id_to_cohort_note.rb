class AddUserIdToCohortNote < ActiveRecord::Migration
  def change
    add_column :cohort_client_notes, :user_id, :integer, null: false
  end
end
