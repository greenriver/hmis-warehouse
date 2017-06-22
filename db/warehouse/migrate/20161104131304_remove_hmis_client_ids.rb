class RemoveHmisClientIds < ActiveRecord::Migration
  def up
    drop_table :hmis_client_ids
  end
end
