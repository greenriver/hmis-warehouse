class OauthPermission < ActiveRecord::Migration[6.1]
  def up
    ::Role.ensure_permissions_exist
    ::Role.reset_column_information
  end
end
