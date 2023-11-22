class ColocatedWarehouseVersions < ActiveRecord::Migration[6.1]
  def change
    create_table :versions do |t|
      t.string   :item_type, null: false
      t.bigint   :item_id,   null: false
      t.string   :event,     null: false
      t.string   :whodunnit
      t.jsonb    :object
      t.jsonb    :object_changes
      t.datetime :created_at
      t.string :session_id
      t.string :request_id
      t.references :user, index: false
      # additional cols tracked for UserViewableEntity
      t.references :referenced_user, index: false
      t.string :referenced_entity_name
      t.references :migrated_app_version, index: false, comment: 'app database version record'
    end
    add_index :versions, [:item_type, :item_id]
  end
end
