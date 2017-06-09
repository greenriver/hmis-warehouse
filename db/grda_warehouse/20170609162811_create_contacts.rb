class CreateContacts < ActiveRecord::Migration
  def up
    create_table :contacts do |t|
      t.string :type, index: true, null: false
      t.references :entity, index: true, null: false
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.timestamps
    end

    drop_table :project_contacts
  end

  def down
    drop_table :contacts
    create_table :project_contacts do |t|
      t.references :project, index: true, null: false
      t.string :email, null: false
      t.string :first_name
      t.string :last_name
      t.datetime :deleted_at
      t.timestamps

    end
  end
end
