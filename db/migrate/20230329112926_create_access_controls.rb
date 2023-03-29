class CreateAccessControls < ActiveRecord::Migration[6.1]
  def change
    create_table :access_controls do |t|

      t.references :access_group
      t.references :role
      t.timestamp :deleted_at
      t.timestamps
    end

    create_table :user_access_controls do |t|
      t.references :access_control
      t.references :user
      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
