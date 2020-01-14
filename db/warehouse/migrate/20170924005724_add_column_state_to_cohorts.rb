class AddColumnStateToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :column_state, :json
  end
end
