class AlterUniqueViewableEntityConstraint < ActiveRecord::Migration
  def change
    add_index :user_viewable_entities, [:user_id, :entity_id, :entity_type, :deleted_at], unique: true, name: 'one_entity_per_type_per_user_allows_delete'
    remove_index :user_viewable_entities, name: 'one_entity_per_type_per_user'
  end
end
