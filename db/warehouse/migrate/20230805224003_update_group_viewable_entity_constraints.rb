class UpdateGroupViewableEntityConstraints < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_index)
    remove_index :group_viewable_entities, [:access_group_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_group'
    add_index :group_viewable_entities, [:access_group_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_group', where: 'access_group_id != 0'
    add_index :group_viewable_entities, [:collection_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_collection', where: 'collection_id is not NULL'
    ensure
      StrongMigrations.enable_check(:add_index)
  end
end
