class AddVisibleInCasToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :visible_in_cas, :boolean, default: true, null: false
  end
end
