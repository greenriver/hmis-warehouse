class AddSystemCohortFlag < ActiveRecord::Migration[5.2]
  def change
    add_column :cohorts, :system_cohort, :boolean, default: false
    add_column :cohorts, :type, :string, default: 'GrdaWarehouse::Cohort'
  end
end
