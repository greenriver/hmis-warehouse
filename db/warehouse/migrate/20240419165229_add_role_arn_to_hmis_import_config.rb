class AddRoleArnToHmisImportConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_import_configs, :s3_role_arn, :string
  end
end
