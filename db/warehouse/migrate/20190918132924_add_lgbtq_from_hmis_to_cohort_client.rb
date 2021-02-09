class AddLgbtqFromHmisToCohortClient < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :lgbtq_from_hmis, :string
  end
end
