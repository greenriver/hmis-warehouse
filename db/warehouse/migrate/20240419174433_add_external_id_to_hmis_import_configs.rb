class AddExternalIdToHmisImportConfigs < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_import_configs, :s3_external_id, :string
  end
end
