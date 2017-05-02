class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.string :name, null: false, index: true, unique: true
      t.string :verb
      t.timestamps null: false
    end

    create_table :user_roles do |t|
      t.belongs_to :role, index: true
      t.belongs_to :user, index: true
      t.timestamps null: false
    end

    add_foreign_key :user_roles, :roles, on_delete: :cascade
    add_foreign_key :user_roles, :users, on_delete: :cascade
  end
end
