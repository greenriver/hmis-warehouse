class ChangeColumnStateType < ActiveRecord::Migration[4.2]
  def change
    remove_column :cohorts, :column_state, :json
    add_column :cohorts, :column_state, :text
  end
end
