class CohortMostRecentCls < ActiveRecord::Migration[7.0]
  def change
    add_column :cohort_clients, :most_recent_cls, :string
    add_column :cohort_clients, :most_recent_prior_living_situation, :string
    add_column :cohort_clients, :most_recent_household_type, :string
    add_column :cohort_clients, :most_recent_self_report_months_homeless, :string
    add_column :cohort_clients, :most_recent_disabling_condition, :string
  end
end
