class RemoveCanViewCensus < ActiveRecord::Migration[5.2]
  def up
    remove_column :roles, :can_view_censuses
    Role.reset_column_information
  end

  def down
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
end
