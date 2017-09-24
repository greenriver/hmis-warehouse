class AddDateToCohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :effective_date, :date
  end
end
