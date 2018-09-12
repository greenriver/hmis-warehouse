class AdditionalCohortColumsLgbtq < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :lgbtq, :boolean
    add_column :cohort_clients, :sleeping_location, :string
    add_column :cohort_clients, :exit_destination, :string
  end
end
