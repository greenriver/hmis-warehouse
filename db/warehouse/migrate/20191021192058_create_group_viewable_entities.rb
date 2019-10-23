class CreateGroupViewableEntities < ActiveRecord::Migration
  def change
    create_table :group_viewable_entities do |t|
      t.references :access_group, null: false
      t.references :entity, null: false, polymorphic: true

      t.datetime :deleted_at

      t.index [:access_group_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_group'
    end
  end
end
