class AddGenerateHomelessVerificationPdfsToRoles < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_generate_homeless_verification_pdfs
  end
end
