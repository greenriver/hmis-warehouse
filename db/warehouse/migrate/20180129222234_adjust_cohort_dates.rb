class AdjustCohortDates < ActiveRecord::Migration
  def change
    change_column :cohort_clients, :first_date_homeless, :date
    change_column :cohort_clients, :last_date_approached, :date
  end
end
