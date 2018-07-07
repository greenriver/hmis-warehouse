class AddCareCoordinatorToPatient < ActiveRecord::Migration
  def change
    add_column :patients, :care_coordinator_id, :integer
  end
end
