class CreateGrdaWarehouseUserClientPermissions < ActiveRecord::Migration[5.2]
  def change
    create_table :user_client_permissions do |t|
      t.integer 'user_id', null: false
      t.integer 'client_id', null: false
      t.boolean 'viewable', default: false
      t.timestamps
      t.index ['user_id']
      t.index ['client_id']
    end
  end
end
