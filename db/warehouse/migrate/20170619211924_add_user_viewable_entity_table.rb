class AddUserViewableEntityTable < ActiveRecord::Migration[4.2]
  def change
    create_table :user_viewable_entities do |t|
      t.references :user, null: false
      t.references :entity, null: false, polymorphic: true
      t.index [:user_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_user'
    end
  end
end
