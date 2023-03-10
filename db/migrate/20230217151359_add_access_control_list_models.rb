class AddAccessControlListModels < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_access_controls do |t|
      t.references :access_group
      t.references :role
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :hmis_user_access_controls do |t|
      t.references :access_control
      t.references :user
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
