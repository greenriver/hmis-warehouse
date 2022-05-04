class SetExistingImportConfigsKinds < ActiveRecord::Migration[6.1]
  def change
    Health::ImportConfig.update_all(protocol: :sftp, kind: :epic_data)
  end
end
