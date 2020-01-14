class RemoveHmisClientIds < ActiveRecord::Migration[4.2]
  def up
    drop_table :hmis_client_ids
  end
end
