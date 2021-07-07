class AddSystemCohortsConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :enable_system_cohorts, :boolean, default: false
    add_column :configs, :currently_homeless_cohort, :boolean, default: false
  end
end
