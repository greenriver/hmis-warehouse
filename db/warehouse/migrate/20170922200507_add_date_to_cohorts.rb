class AddDateToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :active_date, :date
  end
end
