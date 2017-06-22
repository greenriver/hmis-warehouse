class FixIndexClientXStaff < ActiveRecord::Migration
  def change
    table_name = GrdaWarehouse::HMIS::StaffXClient.table_name
    remove_index table_name, column: [:staff_id, :client_id]
    add_index table_name, [:staff_id, :client_id, :relationship_id], unique: true, name: :index_staff_x_client_s_id_c_id_r_id
  end
end
