class AddActiveToChohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :active_cohort, :boolean, default: true, null: false
  end
end
