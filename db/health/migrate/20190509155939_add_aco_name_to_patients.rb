class AddAcoNameToPatients < ActiveRecord::Migration
  def change
    add_column :patients, :aco_name, :string
  end
end
