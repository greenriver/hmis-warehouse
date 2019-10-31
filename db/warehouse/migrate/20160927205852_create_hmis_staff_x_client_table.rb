class CreateHmisStaffXClientTable < ActiveRecord::Migration[4.2]
  def change
    table_name = GrdaWarehouse::HMIS::StaffXClient.table_name
    create_table table_name do |t|
      t.integer :staff_id
      t.integer :client_id
      t.integer :relationship_id
    end
    add_index table_name, [:staff_id, :client_id], unique: true
  end
end
