class AddHmisDestinationToCohortClient < ActiveRecord::Migration
  def change
    add_column :cohort_clients, :hmis_destination, :string
  end
end
