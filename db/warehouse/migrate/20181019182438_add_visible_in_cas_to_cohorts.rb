class AddVisibleInCasToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :visible_in_cas, :boolean, default: true, null: false
  end
end
