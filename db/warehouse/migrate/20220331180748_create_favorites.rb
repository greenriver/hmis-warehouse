class CreateFavorites < ActiveRecord::Migration[6.1]
  def change
    create_table :favorites do |t|
      t.references :user, null: false
      t.references :entity, null: false, polymorphic: true

      t.timestamps null: false, index: true
    end
  end
end
