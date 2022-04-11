class CreateFavorites < ActiveRecord::Migration[6.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false
      t.references :entity, null: false, polymorphic: true

      t.timestamps null: false, index: true

      t.index [:user_id, :entity_id, :entity_type], unique: true, name: 'one_entity_per_type_per_id_per_user'
    end
  end
end
