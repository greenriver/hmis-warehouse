
class CreateMembers < ActiveRecord::Migration
  def change
    create_table :team_members do |t|
      t.string :type, null: false, index: true
      t.references :team, null: false, index: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :organization
      t.string :title
      t.date :last_contact

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
