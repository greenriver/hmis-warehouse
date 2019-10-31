class InactiveDaysForCohorts < ActiveRecord::Migration[4.2]
  def change
    add_column :cohorts, :days_of_inactivity, :integer, default: 90
  end
end
