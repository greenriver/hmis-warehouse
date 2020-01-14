class CreateAccessGroupMembers < ActiveRecord::Migration[4.2]
  def change
    create_table :access_group_members do |t|
      t.references :access_group
      t.references :user

      t.datetime :deleted_at
    end
  end
end
