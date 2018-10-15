class ConvertLgbtqCohortColumn < ActiveRecord::Migration
  def change
    rename_column :cohort_clients, :lgbtq, :lgbtq_boolean
    add_column :cohort_clients, :lgbtq, :string
  end
end
