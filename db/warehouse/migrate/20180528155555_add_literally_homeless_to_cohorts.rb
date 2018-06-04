class AddLiterallyHomelessToCohorts < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :adjusted_days_literally_homeless_last_three_years, :integer
  end
end
