class AddDateToCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :effective_date, :date
  end
end
