class ChangeColumnStateType < ActiveRecord::Migration
  def change
    remove_column :cohorts, :column_state, :json
    add_column :cohorts, :column_state, :text
  end
end
