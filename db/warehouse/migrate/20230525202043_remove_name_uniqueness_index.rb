class RemoveNameUniquenessIndex < ActiveRecord::Migration[6.1]
  def up
    remove_index :CustomClientName, name: "unique_index_ensuring_one_primary_per_client"
  end

  def down
    execute('CREATE UNIQUE INDEX unique_index_ensuring_one_primary_per_client ON "CustomClientName" ("PersonalID", data_source_id) WHERE "primary" = true')
  end
end
