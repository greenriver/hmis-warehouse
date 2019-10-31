class ConvertLgbtqCohortColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :cohort_clients, :lgbtq, :lgbtq_boolean
    add_column :cohort_clients, :lgbtq, :string
  end
end
