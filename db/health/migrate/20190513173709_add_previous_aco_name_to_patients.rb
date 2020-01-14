class AddPreviousAcoNameToPatients < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :patients, :previous_aco_name, :string
  end
end
