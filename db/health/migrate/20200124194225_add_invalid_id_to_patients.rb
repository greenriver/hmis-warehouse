class AddInvalidIdToPatients < ActiveRecord::Migration[5.2]
  def change
    add_column :patients, :invalid_id, :boolean, default: false
  end
end
