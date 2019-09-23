class AddLgbtqFromHmisToCohortClient < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :lgbtq_from_hmis, :string
  end
end
