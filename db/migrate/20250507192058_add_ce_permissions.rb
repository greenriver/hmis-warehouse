class AddCePermissions < ActiveRecord::Migration[7.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information
  end

  def down

  end
end
