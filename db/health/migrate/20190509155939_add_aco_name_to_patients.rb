class AddAcoNameToPatients < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :aco_name, :string
  end
end
