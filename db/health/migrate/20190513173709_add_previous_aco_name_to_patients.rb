class AddPreviousAcoNameToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :previous_aco_name, :string
  end
end
