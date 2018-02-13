class AdditionalCohortClientColumns < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :housing_navigator, :string
    add_column :cohort_clients, :status, :string
    add_column :cohort_clients, :ssvf_eligible, :string
    add_column :cohort_clients, :location, :string
    add_column :cohort_clients, :location_type, :string
    add_column :cohort_clients, :vet_squares_confirmed, :string
  end
end
