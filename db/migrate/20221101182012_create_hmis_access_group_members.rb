class CreateHmisAccessGroupMembers < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_access_group_members do |t|
      t.references :access_group
      t.references :user
      t.timestamps
      t.timestamp :deleted_at
    end
  end
end
