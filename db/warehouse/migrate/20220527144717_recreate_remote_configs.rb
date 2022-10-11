class RecreateRemoteConfigs < ActiveRecord::Migration[6.1]
  def change
    create_table :remote_configs do |t|
      t.string :type, null: false
      t.references :remote_credential
      t.boolean :active, default: false

      t.timestamps
      t.datetime :deleted_at
    end

    add_column :remote_credentials, :deleted_at, :datetime
  end
end
