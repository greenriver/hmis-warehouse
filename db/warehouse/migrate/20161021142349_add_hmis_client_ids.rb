class AddHmisClientIds < ActiveRecord::Migration[4.2]
  def change
    create_table :hmis_client_ids do |t|
      t.string :hmis_id
      t.string :personal_id
      t.timestamps null: false
    end
  end
end
