class AddChronicTabPermmission < ActiveRecord::Migration[6.1]
  def up
     Role.ensure_permissions_exist
     Role.reset_column_information
     # default to old behavior
     Role.where(can_edit_clients: true).update_all(can_view_chronic_tab: true)
   end

   def down
     remove_column :roles, :can_view_chronic_tab
   end
end
