class AddColumnStateToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :column_state, :json
  end
end
