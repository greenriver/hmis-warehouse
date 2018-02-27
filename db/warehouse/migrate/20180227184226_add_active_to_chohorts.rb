class AddActiveToChohorts < ActiveRecord::Migration
  def change
    add_column :cohorts, :active_cohort, :boolean, default: true, null: false
  end
end
