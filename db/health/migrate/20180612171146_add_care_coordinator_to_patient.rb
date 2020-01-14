class AddCareCoordinatorToPatient < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :care_coordinator_id, :integer
  end
end
