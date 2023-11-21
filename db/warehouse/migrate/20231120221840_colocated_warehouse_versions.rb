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
    end
    add_index :versions, [:item_type, :item_id]
  end
end
