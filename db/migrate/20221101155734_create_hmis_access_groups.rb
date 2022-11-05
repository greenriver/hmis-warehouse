class CreateHmisAccessGroups < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_access_groups do |t|
      t.string :name, null: false
      t.timestamps
      t.timestamp :deleted_at
    end
  end
end
