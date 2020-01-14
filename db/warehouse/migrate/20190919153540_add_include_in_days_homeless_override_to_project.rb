class AddIncludeInDaysHomelessOverrideToProject < ActiveRecord::Migration[4.2]
  def change
    add_column :Project, :include_in_days_homeless_override, :boolean, default: false
  end
end
