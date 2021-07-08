class AddSystemCohortFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :cohorts, :system_cohort, :boolean, default: false
  end
end
