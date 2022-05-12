class AddSystemCohortDatesToConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :system_cohort_processing_date, :date
    add_column :configs, :system_cohort_date_window, :integer, default: 1
  end
end
