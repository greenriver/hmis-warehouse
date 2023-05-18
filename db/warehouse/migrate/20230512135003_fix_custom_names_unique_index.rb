class FixCustomNamesUniqueIndex < ActiveRecord::Migration[6.1]
  def up
    execute('DROP INDEX unique_index_ensuring_one_primary_per_client')
    execute('CREATE UNIQUE INDEX unique_index_ensuring_one_primary_per_client ON "CustomClientName" ("PersonalID", data_source_id) WHERE "primary" = true')
  end

  def down
    execute("DROP INDEX unique_index_ensuring_one_primary_per_client")
    execute('CREATE UNIQUE INDEX unique_index_ensuring_one_primary_per_client ON "CustomClientName" ("PersonalID", data_source_id, "primary") ')
  end
end
