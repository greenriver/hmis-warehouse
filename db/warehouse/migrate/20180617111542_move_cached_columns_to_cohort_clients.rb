class MoveCachedColumnsToCohortClients < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :calculated_days_homeless_on_effective_date, :integer
    add_column :cohort_clients, :days_homeless_last_three_years_on_effective_date, :integer
    add_column :cohort_clients, :days_literally_homeless_last_three_years_on_effective_date, :integer
    add_column :cohort_clients, :destination_from_homelessness, :string
    add_column :cohort_clients, :related_users, :string
    add_column :cohort_clients, :disability_verification_date, :date
    add_column :cohort_clients, :missing_documents, :string
  end
end
