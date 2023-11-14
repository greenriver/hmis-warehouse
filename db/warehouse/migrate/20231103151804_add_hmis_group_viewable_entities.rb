class AddHmisGroupViewableEntities < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_group_viewable_entities do |t|
      t.references :entity, polymorphic: true, null: false
      t.references :collection, null: false
      t.datetime :deleted_at
    end
  end
end
