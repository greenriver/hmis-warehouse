class CreateHmisUserGroups < ActiveRecord::Migration[6.1]
  def change
    StrongMigrations.disable_check(:add_reference)
    create_table :hmis_user_groups do |t|
      t.string :name
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :hmis_user_group_members do |t|
      t.references :user_group
      t.references :user
      t.timestamp :deleted_at
      t.timestamps
    end

    add_reference :hmis_access_controls, :user_group
  ensure
    StrongMigrations.enable_check(:add_reference)
  end
end
