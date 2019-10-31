class AddHmisDestinationToCohortClient < ActiveRecord::Migration[4.2]
  def change
    add_column :cohort_clients, :hmis_destination, :string
  end
end
