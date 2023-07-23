class CreateAccessControls < ActiveRecord::Migration[6.1]
  def change
    create_table :user_groups do |t|
      t.string :name
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :user_group_members do |t|
      t.references :user_group
      t.references :user
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :collections do |t|
      t.string :name
      t.jsonb :coc_codes, default: {}
      t.jsonb :system, default: []
      t.boolean :must_exist, null: false, default: false
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :access_controls do |t|
      t.references :collection
      t.references :role
      t.references :user_group
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
